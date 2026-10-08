import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates procedural 44.1kHz 16-bit mono WAV files for Unwind game audio.
void main() {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // 1. pull.ogg - Smooth sliding swoosh with wooden friction
  File('${outDir.path}/pull.ogg').writeAsBytesSync(
    generatePullSwoosh(),
  );

  // 2. block.ogg - Soft muted wood tap
  File('${outDir.path}/block.ogg').writeAsBytesSync(
    generateBlockTap(),
  );

  // 3. complete.ogg - Gentle warm two-note acoustic chime resolve
  File('${outDir.path}/complete.ogg').writeAsBytesSync(
    generateCompleteChime(),
  );

  // 4. ui.ogg - Subtle crisp tactile tick
  File('${outDir.path}/ui.ogg').writeAsBytesSync(
    generateUiTick(),
  );

  stdout.writeln('Audio files generated successfully in assets/audio/');
}

List<int> createWavFile(List<double> samples, {int sampleRate = 44100}) {
  final numSamples = samples.length;
  const numChannels = 1;
  const bitsPerSample = 16;
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  const blockAlign = numChannels * (bitsPerSample ~/ 8);
  final dataSize = numSamples * (bitsPerSample ~/ 8);
  final chunkSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);
  // RIFF header
  buffer.setUint8(0, 0x52); // 'R'
  buffer.setUint8(1, 0x49); // 'I'
  buffer.setUint8(2, 0x46); // 'F'
  buffer.setUint8(3, 0x46); // 'F'
  buffer.setUint32(4, chunkSize, Endian.little);
  buffer.setUint8(8, 0x57); // 'W'
  buffer.setUint8(9, 0x41); // 'A'
  buffer.setUint8(10, 0x56); // 'V'
  buffer.setUint8(11, 0x45); // 'E'

  // fmt subchunk
  buffer.setUint8(12, 0x66); // 'f'
  buffer.setUint8(13, 0x6D); // 'm'
  buffer.setUint8(14, 0x74); // 't'
  buffer.setUint8(15, 0x20); // ' '
  buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  buffer.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
  buffer.setUint16(22, numChannels, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, blockAlign, Endian.little);
  buffer.setUint16(34, bitsPerSample, Endian.little);

  // data subchunk
  buffer.setUint8(36, 0x64); // 'd'
  buffer.setUint8(37, 0x61); // 'a'
  buffer.setUint8(38, 0x74); // 't'
  buffer.setUint8(39, 0x61); // 'a'
  buffer.setUint32(40, dataSize, Endian.little);

  for (var i = 0; i < numSamples; i++) {
    final s = samples[i].clamp(-1.0, 1.0);
    final val = (s * 32767.0).round().toInt();
    buffer.setInt16(44 + i * 2, val, Endian.little);
  }

  return buffer.buffer.asUint8List();
}

List<int> generatePullSwoosh({int sampleRate = 44100}) {
  const duration = 0.28;
  final numSamples = (duration * sampleRate).toInt();
  final samples = List<double>.filled(numSamples, 0.0);
  final rand = Random(42);

  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = t / duration;

    // Envelope: quick rise (15%), smooth exponential decay
    final env =
        progress < 0.15 ? (progress / 0.15) : exp(-4.5 * (progress - 0.15));

    // Pitch bends slightly upward then stabilizes
    final f = 340.0 + 120.0 * sin(progress * pi * 0.9);
    final tone = sin(2 * pi * f * t) * 0.5 + sin(2 * pi * (f * 1.5) * t) * 0.2;
    // Filtered noise for cloth/thread texture
    final noise = (rand.nextDouble() * 2 - 1) * 0.15 * exp(-6.0 * progress);

    samples[i] = (tone + noise) * env * 0.75;
  }
  return createWavFile(samples, sampleRate: sampleRate);
}

List<int> generateBlockTap({int sampleRate = 44100}) {
  const duration = 0.15;
  final numSamples = (duration * sampleRate).toInt();
  final samples = List<double>.filled(numSamples, 0.0);
  final rand = Random(123);

  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = t / duration;

    // Fast sharp percussive envelope
    final env = exp(-28.0 * progress);
    const f1 = 180.0;
    const f2 = 240.0;
    final body = sin(2 * pi * f1 * t) * 0.6 + sin(2 * pi * f2 * t) * 0.3;
    final click = (rand.nextDouble() * 2 - 1) * 0.3 * exp(-60.0 * progress);

    samples[i] = (body + click) * env * 0.85;
  }
  return createWavFile(samples, sampleRate: sampleRate);
}

List<int> generateCompleteChime({int sampleRate = 44100}) {
  const duration = 0.75;
  final numSamples = (duration * sampleRate).toInt();
  final samples = List<double>.filled(numSamples, 0.0);

  // Note 1: E5 (659.25 Hz) at t=0, Note 2: G#5 / A5 (880.0 Hz) at t=0.12s
  const note1Freq = 587.33; // D5
  const note2Freq = 880.00; // A5
  const note2Start = 0.12;

  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    var s1 = 0.0;
    final env1 = exp(-4.5 * t);
    s1 = (sin(2 * pi * note1Freq * t) +
            0.35 * sin(2 * pi * (note1Freq * 2) * t)) *
        env1;

    var s2 = 0.0;
    if (t >= note2Start) {
      final t2 = t - note2Start;
      final env2 = exp(-3.8 * t2);
      s2 = (sin(2 * pi * note2Freq * t2) +
              0.4 * sin(2 * pi * (note2Freq * 2) * t2) +
              0.15 * sin(2 * pi * (note2Freq * 3) * t2)) *
          env2;
    }

    samples[i] = (s1 * 0.45 + s2 * 0.65) * 0.75;
  }
  return createWavFile(samples, sampleRate: sampleRate);
}

List<int> generateUiTick({int sampleRate = 44100}) {
  const duration = 0.04;
  final numSamples = (duration * sampleRate).toInt();
  final samples = List<double>.filled(numSamples, 0.0);

  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = t / duration;
    final env = exp(-45.0 * progress);
    final tone = sin(2 * pi * 820.0 * t) * 0.7;

    samples[i] = tone * env * 0.6;
  }
  return createWavFile(samples, sampleRate: sampleRate);
}
