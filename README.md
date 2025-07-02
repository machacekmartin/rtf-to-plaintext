# RTF Extractor

This is a Perl script that extracts plain text from RTF input.

# Why does this exist
Every tool I used failed to extract my input properly, f.e. missing new lines, wrong czech characters extraction (accents), extra rtf blocks that were supposed to be ignored... 

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
