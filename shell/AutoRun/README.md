## AutoRun
This script monitors the changes under a given directory. It'll do something automatic, if a file is changed  
## Usage
```bash
auto_run.py [-c config file] dirname  
```
config file is used to define the white-black-list of detected files. The default config file is ignore.conf. You can change it or define a new one  

`do_something.sh` used to deliever file information to rules, and accrodingly chooses out the responding rule and acts it out.
`rules.json` is a json file used to restore rules. Each rule consists of three conditions and an action. Three conditions are running environment, fullname and extension of the detected file. If one of them is matched, the action will be done. The first matched action will be done. You can rewrite the file to define your own rules

## Example
```bash
auto_run.py .
```
run the script and resave test.py, then you will find the followed response:  
```
Just a test 
```
