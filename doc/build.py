#!/usr/bin/env python
from subprocess import call
import glob, os

texDir = './tex/'
texMaster = 'report'

print('\nBuilding LaTeX with latex-mk...')
os.chdir(texDir)
texBuildCommand = 'latexmk -pdf {0}'.format(texMaster)
texCleanCommand = 'latexmk -c'
call(texBuildCommand, shell=True)
call(texCleanCommand, shell=True)
