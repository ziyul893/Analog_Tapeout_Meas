% Import the data
clear;
close all;

% Define file names with 5dB increments from -30dB to 10dB
db_values = -35:5:0;
file_prefix = 'T10/Qn3/51Hz/';
file_extension = 'dBm.csv';

% Pre-allocate arrays to store SNR and SNDR for each file
snr_results = zeros(length(db_values), 1);
sndr_results = zeros(length(db_values), 1);

% Loop over each file
for idx = 1:length(db_values)
    % Construct the file name
    filename = sprintf('%s%d%s', file_prefix, db_values(idx), file_extension);
    fprintf('Processing file: %s\n', filename);

    % Read data from the current file
    data = readtable(filename);

    % Extract time string and convert to milliseconds
    time_ms = zeros(size(data, 1), 1);  % Pre-allocate for speed
    for i = 1:size(data, 1)
        time_str = data.Time{i};
        if endsWith(time_str, 's')
            time_ms(i) = str2double(time_str(1:end-2)) * 1000; % Convert seconds to ms
        elseif endsWith(time_str, 'ms')
            time_ms(i) = str2double(time_str(1:end-3));
        elseif endsWith(time_str, 'us')
            time_ms(i) = str2double(time_str(1:end-3)) / 1000;
        else
            error('Unknown time unit in row %d: %s', i, time_str);
        end
    end

    % Replace the original time column
    data.Time = time_ms;

    % Combine the 12 bits into a single decimal value
    decimal_value = data.D11 * 2^11 + data.D10 * 2^10 + data.D9 * 2^9 + data.D8 * 2^8 + ...
                    data.D7 * 2^7 + data.D6 * 2^6 + data.D5 * 2^5 + data.D4 * 2^4 + ...
                    data.D3 * 2^3 + data.D2 * 2^2 + data.D1 * 2^1 + data.D0;

    % Convert to voltage
    voltage = (decimal_value / (2^12 - 1)) * 5; 

    % Calculate the sampling rate
    Fs = 1000 / (time_ms(2) - time_ms(1));  % Assuming uniform sampling

    % Blackman-Harris Window
    L = length(voltage);
    win = blackmanharris(L);

    % Perform the FFT
    Y = fft(voltage .* win);

    % Calculate the frequency axis
    f = Fs * (0:(L/2)) / L;

    % Compute the two-sided spectrum and single-sided spectrum
    P2 = abs(Y / L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2 * P1(2:end-1);

    P1_db = 10 * log10(P1);

    % Plot the single-sided amplitude spectrum (optional)
    % figure;
    % plot(f, P1_db);
    % title(sprintf('Single-Sided Amplitude Spectrum for %d dB', db_values(idx)));
    % xlabel('Frequency (Hz)');
    % ylabel('Amplitude (dB)');

    % Calculate and store SNR and SNDR for the current file
    snr_results(idx) = snr(decimal_value, Fs);  % SNR in dB
    sndr_results(idx) = sinad(decimal_value, Fs);  % SNDR in dB
end

% Display the SNR and SNDR results
disp('SNR and SNDR Results (dB):');
for idx = 1:length(db_values)
    fprintf('File %d dB: SNR = %.2f dB, SNDR = %.2f dB\n', db_values(idx), snr_results(idx), sndr_results(idx));
end
