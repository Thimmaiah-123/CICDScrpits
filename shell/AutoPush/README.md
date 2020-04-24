## AutoPush
This script adds, commits and pushs your codes automatically.
## Usage
```bash
auto_push.py [-c config file] dirname
```
config file is used to define the white-black-list of detected files. The default config file is ignore.conf. You can change it or define a new one.  

`push.sh` is used to define your command after detecting out a changed file. You can rewrite this script.  

## Commands

```py
#@git: <example.py>
#@git branch master
#@git: <class Example> This is an example class
class Example:
  #@git: init
  def __init__(self):
    pass
  #git: <Example.example> An example function
  def example(self):
    pass
```
`#@git: <?>` defines a label, the code under this label is commited with message with this label. The commits with the same label are squashed.  
`#@git branch` defines the working branch.  
`#@git:` defines a message without label, it inherits the nearest upper label.
