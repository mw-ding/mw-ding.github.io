#!/bin/bash

echo 'Build Site'
hugo

echo 'List the built output directory'
ls -al ./public
