close all;
clear all;
[y fs]= audioread('NSph.wav');
signal_len = length(y);
frame_len=0.01*fs;
frame_step=0.005*fs;
num_frames =1+ ceil((signal_len - frame_len)/frame_step);
padded_len = (num_frames-1)*frame_step + frame_len;
% making sure signal is exactly divisible into N frames
padded_y = [y', zeros(1, padded_len - signal_len)];
%calculating frame indices
indices = repmat(1:frame_len, num_frames, 1) + repmat((0: frame_step: num_frames*frame_step-1)', 1, frame_len);
frames = padded_y(indices);
noise_frames = floor(0.5*fs/frame_step);
window_fn = repmat(hamming(frame_len)', size(frames, 1), 1);
windowed_frames = frames.* window_fn;
%%%% Calculating Power spectrum of each frame%%%%%%%%%
Y_spec = fft(frames,frame_len,2);% complex spectrum
figure(2);
subplot(3,1,1);
plot(abs(Y_spec(noise_frames,:)));
title('Magnitude Spectrum of Noisy signal of a single frame');
xlabel('Samples');ylabel('Amplitude');
Ymag_spec = abs(Y_spec).^2; % power spectrum of noisy signal
figure(1);
subplot(2,1,1);
plot(Ymag_spec(noise_frames,:));
title('Power Spectrum of Noisy signal of a single frame');
xlabel('Samples');ylabel('Amplitude');
phase = angle(Y_spec); % phase of noisy signal

%%%%  spectral subtraction %%%%%
noise_psd = mean(Ymag_spec(1:noise_frames,:));
clean_spec = Ymag_spec - repmat(noise_psd,size(Ymag_spec,1),1); % subtract noise_est from pspec
clean_spec(clean_spec < 0) = 0; % negative power spectrum is not allowed
figure(1);
subplot(2,1,2);
plot(clean_spec(noise_frames,:));
title('Power Spectrum of clean signal of a single frame');
xlabel('Samples');ylabel('Amplitude');
j=sqrt(-1);
reconstructed_frames = ifft(sqrt((clean_spec).*exp(j*phase)),frame_len,2);
reconstructed_frames = real(reconstructed_frames); 
clean_signal = zeros(1,padded_len);
window_correction = zeros(1,padded_len);
window_fn = hamming(frame_len)';
for i = 1:num_frames
    window_correction(indices(i,:)) = window_correction(indices(i,:)) + window_fn;
    clean_signal(indices(i,:)) = clean_signal(indices(i,:)) + reconstructed_frames(i,:);
end

clean_signal = clean_signal./window_correction;
% sound(clean_signal,fs);
%  sound(y,fs);
figure(3);
subplot(2,1,1);
plot(1:signal_len,y(1:signal_len),1:signal_len,clean_signal(1:signal_len)), grid
title('Noisy signal vs Clean Signal using Spectral Subtraction');
xlabel('Samples');ylabel('Amplitude');
audiowrite('14253291_ss.wav',clean_signal,fs);

%%%%%%%%%  Wiener Filtering  %%%%%%%%

Y_psd=mean(Ymag_spec(1:num_frames,:));
H_w = (Y_psd-noise_psd)./ Y_psd;
figure(2);
subplot(3,1,2);
plot(H_w);
title('Wiener Filter');
xlabel('Samples');ylabel('Amplitude');
Hw_frames= repmat(H_w, size(frames, 1), 1);
Sw_frames= Y_spec.* Hw_frames;
figure(2);
subplot(3,1,3);
plot(abs(Sw_frames(noise_frames,:)));
title('Magnitude Spectrum of clean signal of a single frame');
xlabel('Samples');ylabel('Amplitude');
Sw_frames= ifft(Sw_frames,frame_len,2);
Sn = zeros(1,padded_len);
for i = 1:num_frames
        Sn(indices(i,:)) = Sn(indices(i,:)) + Sw_frames(i,:);
end
Sn = Sn./window_correction;
% sound(Sn,fs);
% %  sound(y,fs);
figure(3);
subplot(2,1,2);
plot(1:signal_len,y(1:signal_len),1:signal_len,Sn(1:signal_len)), grid
title('Noisy signal vs Clean Signal using Wiener Filtering');
xlabel('Samples');ylabel('Amplitude');
axis([0 signal_len -1.5 2.5]);
audiowrite('14253291_wf.wav',Sn,fs);