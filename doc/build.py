#!/usr/bin/env python
from subprocess import call
import glob, os

texDir = './tex/'
texMaster = 'lniguide_en'

print('\nBuilding LaTeX with latex-mk...')
os.chdir(texDir)
texBuildCommand = 'latexmk -pdf {0}'.format(texMaster)
texCleanCommand = 'latexmk -c'
call(texBuildCommand, shell=True)
call(texCleanCommand, shell=True)
