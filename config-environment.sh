#!/bin/bash

rm -f ${PWD}/microservice-auth-service/.devcontainer/.env
rm -f ${PWD}/microservice-users-service/.devcontainer/.env
ln -s ${PWD}/environment/container-hosts.env ${PWD}/microservice-auth-service/.devcontainer/.env
ln -s ${PWD}/environment/container-hosts.env ${PWD}/microservice-users-service/.devcontainer/.env