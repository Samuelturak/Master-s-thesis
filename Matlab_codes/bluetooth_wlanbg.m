clear variables
close all
clc

%% Generating Rayleigh channel 
% Ideal parameters from: https://www.mathworks.com/help/comm/ref/comm.rayleighchannel-system-object.html

fs = 3.84e6;                                  % Sample rate in Hz
pathDelays = [10 200 800 1200 2300 3700]*1e-9; % in seconds
avgPathGains = [0 -0.9 -4.9 -8 -7.8 -23.9];   % dB
fD = 50;                                      % Max Doppler shift in Hz

rayleighchan = comm.RayleighChannel('SampleRate',fs, ...
    'PathDelays',pathDelays, ...
    'AveragePathGains',avgPathGains, ...
    'MaximumDopplerShift',fD);

%% Generating Ricean channel 
% Ideal parameters from: https://www.mathworks.com/help/comm/ref/comm.ricianchannel-system-object.html
fs = 3.84e6;                                  % Sample rate in Hz
pathDelays = [10 200 800 1200 2300 3700]*1e-9; % in seconds
avgPathGains = [0 -0.9 -4.9 -8 -7.8 -23.9];   % dB
kfact = 10;                                   % Rician K-factor
fD = 50;                                      % Max Doppler shift in Hz


ricianChan = comm.RicianChannel( ...
    SampleRate=fs, ...
    PathDelays=pathDelays, ...
    AveragePathGains=avgPathGains, ...
    KFactor=kfact, ...
    MaximumDopplerShift=fD);

%% Generating Bluetooth BR/EDR waveform
% Bluetooth BR/EDR configuration
bluetoothCfg = bluetoothWaveformConfig('Mode', 'BR', ...
    'PacketType', 'DM1', ...
    'LogicalTransportAddress', [0;0;1], ...
    'HeaderControlBits', [1;1;1], ...
    'ModulationIndex', 0.32, ... % 0.32
    'SamplesPerSymbol', 8, ...
    'WhitenInitialization', [1;1;1;1;1;1;1], ...
    'LLID', [1;1], ...
    'FlowIndicator', true);

bluetoothCfg.PayloadLength = 17;
bluetoothCfg.WhitenStatus = 'On';
bluetoothCfg.DeviceAddress = '0123456789AB';
% input bit source:



%% Generating 802.11b/g (DSSS) waveform
% 802.11b/g (DSSS) configuration
dsssCfg = wlanNonHTConfig('Modulation', 'DSSS', ...
    'DataRate', '5.5Mbps', ...
    'Preamble', 'Short', ...
    'LockedClocks', true, ...
    'PSDULength', 1000);


numPackets = 1500;  % Intended number of packets
desired_Length = 256;  % Desired length of each packet in samples

%% Impairments parameters
AWGNs = -10:2:20; % AWGN values
phase_offsets = [-pi/18, -pi/36, 0, pi/36, pi/18];  % Possible phase offsets that can occur
amplitude_imbalances = [-10, -5, 0, 5, 10];   % In [%]
amplitude_imbalances = 20*log10(1+amplitude_imbalances*0.01); % Converting to dB


for j = AWGNs
    waveform = [];
    selectedPacket = []; % Initialize for storing selected packet
    for i = 1:numPackets
        if i <= numPackets/2
            %% Blueotooth generation
            % input bit source:
            in = randi([0 1], bluetoothCfg.PayloadLength*8, 1);  % Random input bits for each packet
            packet_Waveform = bluetoothWaveformGenerator(in, bluetoothCfg);
    
            %% Apply the Rician or Rayleigh channel model to the waveform
            %packet_Waveform = ricianChan(packet_Waveform);
            %packet_Waveform = rayleighchan(packet_Waveform);
    
            packetDuration = bluetoothPacketDuration(bluetoothCfg.Mode, bluetoothCfg.PacketType, bluetoothCfg.PayloadLength);
            filterSpan = 8*any(strcmp(bluetoothCfg.Mode, {'EDR2M', 'EDR3M'}));
            packet_Waveform = packet_Waveform(1:(packetDuration + filterSpan) * bluetoothCfg.SamplesPerSymbol);
        else
            %% WLANb/g generation
            % input bit source:
            in = randi([0, 1], dsssCfg.PSDULength, 1);
            
            % Generation of waveform
            packet_Waveform = wlanWaveformGenerator(in, dsssCfg, ...
                'NumPackets', 1, ...
                'IdleTime', 0);
        end

        %% Downsample the waveform
        % Definition of downsampling factor
        downsamplingFactor = max(1, floor(length(packet_Waveform) / desired_Length));
        %downsampledWaveform = trimmed_Waveform(1:downsamplingFactor:end);
        downsampled_Waveform = downsample(packet_Waveform, downsamplingFactor);
        downsampled_Waveform = downsampled_Waveform(1:min(desired_Length, end));
         

        %% Adding impairments
        % awgn
        %downsampled_Waveform = awgn(downsampled_Waveform, j, "measured");
        signal_power = mean(abs(downsampled_Waveform).^2);
        noise_power = signal_power*10^(-j/10);
        noise = randn(size(downsampled_Waveform))*sqrt(noise_power/2)+1i*randn(size(downsampled_Waveform))*sqrt(noise_power/2);
        downsampled_Waveform = downsampled_Waveform + noise;

        % % Phase offset
        %downsampled_Waveform = downsampled_Waveform * exp(1i*phase_offsets(randi(numel(phase_offsets))));
        % % IQ imbalance - Amplitude imbalance
        %downsampled_Waveform = iqimbal(downsampled_Waveform, amplitude_imbalances(randi(numel(amplitude_imbalances))));
        
        % Reshuffling the data
        random_shuffle = randperm(length(downsampled_Waveform));
        downsampled_Waveform = downsampled_Waveform(random_shuffle);

        %% Adding packets to waveform
        waveform = [waveform; downsampled_Waveform];  % Append adjusted packet's waveform
         

    end

    %% Visualize

    %Constellation Diagram
    constel = comm.ConstellationDiagram('ColorFading', true, ...
        'ShowTrajectory', 0, ...
        'ShowReferenceConstellation', false);
    constel.Title = sprintf('Constellation diagram of Bluetooth %d dB',j);
    segmentIndex = 1;  % Change this to visualize different segments
    constel(waveform((segmentIndex-1)*desired_Length+1:segmentIndex*desired_Length));

        %Constellation Diagram
    constel = comm.ConstellationDiagram('ColorFading', true, ...
        'ShowTrajectory', 0, ...
        'ShowReferenceConstellation', false);
    constel.Title = sprintf('Constellation diagram of 802.11bg %d dB',j);
    segmentIndex = 751;  % Change this to visualize different segments
    constel(waveform((segmentIndex-1)*desired_Length+1:segmentIndex*desired_Length));


    %% Save Waveform Data
    waveStruct.waveform = waveform;  % Creating a nested structure as expected by the loading script
    filename = sprintf('bluetoothWLANbg/bluetoothWLANbg_%ddB',j);
    save(filename,'waveStruct')

end