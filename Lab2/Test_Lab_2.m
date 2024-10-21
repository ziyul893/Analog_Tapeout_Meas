
filename = '2_3.xlsx'; 
data = xlsread(filename);  

[~, ~, raw] = xlsread(filename);  
time_with_units = raw(2:end, 14); 


time = zeros(length(time_with_units), 1); 
for i = 1:length(time_with_units)
    str = time_with_units{i};
    if contains(str, 'ms')
        time(i) = str2double(erase(str, 'ms')) / 1000;  
    elseif contains(str, 's')
        time(i) = str2double(erase(str, 's')); 
    else
        error('Unknown time unit in row %d', i);
    end
end


digital_values = data(:, 2:13);  


bits = 12;  
amplitude = zeros(length(digital_values), 1);  

for i = 1:bits
    amplitude = amplitude + digital_values(:, i) * 2^(bits - i); 
end


amplitude = amplitude / (2^bits - 1);  

figure;
plot(time, amplitude);
title('Reconstructed Sine Wave');
xlabel('Time (s)');
ylabel('Amplitude');
grid on;


L = length(amplitude);           
Fs = 1 / (time(2) - time(1));     
Y = fft(amplitude);               


P2 = abs(Y/L);                   
P1 = P2(1:L/2+1);                
P1(2:end-1) = 2*P1(2:end-1);    

f = Fs*(0:(L/2))/L;            


figure;
plot(f, P1);
title('Frequency Spectrum');
xlabel('Frequency (Hz)');
ylabel('|P1(f)|');
grid on;
