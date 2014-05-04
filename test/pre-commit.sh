#!/bin/bash
echo "Corriendo test antes de commit..."
if [ -f .lasttest ]; then
	test=$(cat .lasttest)
	$test
else
	sudo make test
fi

RESULT=$?
if [ $RESULT -ne 0 ]; then
	echo "No se realiza commit, fallaron lost tests."
	exit 1
else
	exit 0
fi
