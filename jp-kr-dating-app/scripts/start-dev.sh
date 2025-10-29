#!/bin/bash

# Navigate to the server directory and start the development server
cd server
npm run dev &

# Navigate to the mobile app directory and start the development server
cd ../mobile-app
npm start &

# Navigate to the web admin directory and start the development server
cd ../web-admin
npm start &

# Wait for all background processes to finish
wait