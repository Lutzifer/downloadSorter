# downloadSorter
A CLI/GUI tool that keeps the OSX downloads folder sorted based on the source of the downloaded file

## Installation

```
brew tap lutzifer/homebrew-tap
brew install downloadSorter
```

## Usage

```
Usage: downloadSorter [options]
-s, --sourcepath: Path to the Folder which contains the files to process.
-t, --targetpath: Path to the Folder which where the files are processed to. If not given, the sourcepath is used.
-h, --help: Prints a help message.
-d, --dry-run: Print what will happen instead of doing it.
-u, --urldepth: Limits the depth of urls. A value of 2 would shorten www.example.com to example.com. Default is 0 (no limit). Negative values are interpreted as 0.
```
