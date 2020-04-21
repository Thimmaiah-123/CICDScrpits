## AutoRun
This script monitors the changes under a given directory. It'll do something automatic, if a file is changed  
## Usage
```bash
auto_run.py [-c config file] dirname  
```
config file is used to define the white-black-list of detected files. The default config file is ignore.conf. You can change it or define a new one  

`do_something.sh` is used to define your command after detecting out a changed file  

## Example
```bash
auto_run.py .
```
run the script and resave test.py, then you will find the followed response:  
```
Just a test
```
