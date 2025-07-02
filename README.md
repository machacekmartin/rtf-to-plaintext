# RTF Extractor

This is a Perl script that extracts plain text from RTF input.
I made this script to extract RTF into plaintext while keeping czech special characters (accents characters, etc), so your specific usecase results may vary.

## Usage

```bash
perl script.pl "{\rtf1\ansi\deff0 {\fonttbl {\f0 Times;}}\f0\pard Hello{\fonttbl {\f0 Times;}} world\par}"
```

## Usage from PHP
```php
$rtf = json_encode("{\rtf1\\ansi\deff0 {\fonttbl {\f0 Times;}}\f0\pard Hello{\fonttbl {\f0 Times;}} world\par}");
$output = shell_exec("perl script.pl $rtf");
print $output;
```

## Input

- The script expects a valid RTF string as a single, quoted command-line argument.
- Input should be UTF-8 encoded.
- It processes inline RTF text, not file paths or external documents.

## Requirements

- Perl
