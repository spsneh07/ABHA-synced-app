import 'dart:io';

void main() {
  File source = File(r'C:\Users\kaust\.gemini\antigravity-ide\brain\cc57c95f-2aa8-4ce6-bbfe-a1c64a86cb32\mediscan_icon_1782634707187.png');
  Directory('assets').createSync(recursive: true);
  source.copySync('assets/app_icon.png');
  print('Copied successfully!');
}
