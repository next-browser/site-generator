#!/bin/bash
quicklispDir=~/.quicklisp

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CC=gcc \
buildapp --eval "(load \"${quicklispDir}/setup.lisp\")" \
         --asdf-path $dir/ \
         --eval "(ql:quickload :site-generator)" \
         --eval "(defun debug-ignore (c h) (declare (ignore h)) (format t \"~a~%\" c) (abort))" \
         --entry sg::main \
         --output site-generator
