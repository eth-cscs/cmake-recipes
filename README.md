# CMake recipes

This repository is for collecting, curating and maintaining up to date CMake scripts.

## Guidelines

- _**Provide "instructions manual"**_ - Each file should come with an header that explains how to use it and specifies the requirements.

- _**Target a specific CMake version**_ - Each script should call `cmake_minimum_required(VERSION X.Y)` with the target CMake version (and it can optionally set its own policies).