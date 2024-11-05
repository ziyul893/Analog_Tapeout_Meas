% Import the data
clear;
% enter name here
data = readtable('T10/q2_51Hz.csv');

% Extract time string and convert to milliseconds
time_ms = zeros(size(data,1), 1);  % Pre-allocate for speed

for i = 1:size(data,1)
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
Fs = 1000/(time_ms(2)-time_ms(1));  % Assuming uniform sampling

% Blackman-Harris Window
L = length(voltage);
win = blackmanharris(L);

% Perform the FFT
Y = fft(voltage.*win);

% Calculate the frequency axis
f = Fs*(0:(L/2))/L;

% Compute the two-sided spectrum and single-sided spectrum
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

P1_db = 10*log(P1);

figure(1);
plot(data.Time,voltage)

% Calculate SFDR, SNDR, SNR
figure(2);
subplot(2,2,1);
sfdr(decimal_value,Fs);

subplot(2,2,2);
sinad(decimal_value,Fs);

subplot(2,2,3);
snr(decimal_value,Fs); 

% Plot the single-sided amplitude spectrum
subplot(2,2,4);
plot(f,P1_db) 
title('Single-Sided Amplitude Spectrum of Voltage')
xlabel('f (Hz)')
ylabel('P (dB)')