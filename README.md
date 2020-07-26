# Imagism

Imagism is a light-weight image processing server with a simple API. It processes images from a directory,
S3 bucket or can even proxy images from another HTTP server.

## Introduction

To process and serve an image, just hit a running Imagism server with the image file path that you want
to serve relative to the adapter that you've configured (file, S3, or proxy). Imagism
fetches the image file from that adapter and then runs any image processing operations
on it based on the query parameters below.

| Parameter | Description | Example |
| --------- | ----------- | ------- |
| brighten  |             |         |

## Installation
