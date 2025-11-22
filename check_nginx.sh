#!/bin/bash
echo "--- Nginx Sites Enabled ---"
ls -l /etc/nginx/sites-enabled/
echo ""
echo "--- Content of Sites ---"
tail -n +1 /etc/nginx/sites-enabled/*
