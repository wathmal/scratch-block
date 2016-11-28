#!c:\program files\python\python.exe
# EASY-INSTALL-ENTRY-SCRIPT: 'nodemcu-uploader==0.4.1','console_scripts','nodemcu-uploader'
__requires__ = 'nodemcu-uploader==0.4.1'
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    sys.exit(
        load_entry_point('nodemcu-uploader==0.4.1', 'console_scripts', 'nodemcu-uploader')()
    )
