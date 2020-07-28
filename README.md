# Imagism

Imagism is a simple image processing server with a query parameter based API.
It processes images from a local directory on the filesystem or a S3 bucket.
Imagism is built with Elixir for HTTP serving and a NIF built with Rust for the image processing.

## Usage

To process and serve an image, just hit a running Imagism server with the image file path that you want
to serve relative to the adapter that you've configured (file or S3). Imagism
fetches the image file from that adapter and then runs any image processing operations
on it based on the query parameters below.

| Parameter | Description                                                                    | Values                             |
| --------- | ------------------------------------------------------------------------------ | ---------------------------------- |
| brighten  | Adjusts the image by a negative or positive value.                             | `-1000` to `1000`                  |
| blur      | Performs a Gaussian blur on the image by an amount.                            | `0.0-100.0`                        |
| flip      | Flips the image horizontally, vertically or both.                              | `v`, `h` or `hv`                   |
| w         | The width to resize the image to.                                              | `0-inf`                            |
| h         | The height to resize the image to.                                             | `0-inf`                            |
| resize    | The strategy for resizing the image. See **Resizing** below.                   | `exact`, `fit` or `crop`           |
| crop      | The stragegy for cropping the image if `?resize=crop`. See **Resizing** below. | `top`, `left`, `right` or `bottom` |

For example, `http://localhost:8000/sloth.jpg?w=500&flip=v` will load `sloth.jpg`, resize it to 500 pixels wide
while maintaining the aspect ratio and then will flip the image vertically.

### Resizing

If `?resize=exact`, then `?w` and `?h` will be used to resize the image exactly. If either `w` or `h` are missing
then the image's existing dimension will be used.

If `?resize=crop`, then the image will be cropped to fit `?w` and `?h`. If either `w` or `h` is missing
then the image's current aspect ratio will be used to guess the missing dimension. To choose where the crop
should be taken from, set `?crop` to `bottom`, `left`, `top`, `right` or a combination of both like `top,right`.

If `?resize=fit` (or `?resize` isn't set but `w` and `h` are), then the image will be resized to fit `?w` and `?h`.
If either `w` or `h` is missing then the image's current aspect ratio will be used to guess the missing dimension.

## Setup

Imagism is configured through environment variables. If you're running it locally you can use `.env`.

| Variable              | Description                                                   | Example                       |
| --------------------- | ------------------------------------------------------------- | ----------------------------- |
| IMAGISM_ADAPTER       | The adapter to load images via                                | `file` or `s3`                |
| IMAGISM_FILE_PATH     | The file path to load images from if using the `file` adapter | `some/path/containing/images` |
| IMAGISM_S3_BUCKET     | The S3 bucket to load images from if using the `s3` adapter   | `bucket-name`                 |
| AWS_ACCESS_KEY_ID     | The AWS access key to use with the `s3` adapter               | `<secret>`                    |
| AWS_SECRET_ACCESS_KEY | The AWS secret key to use with the `s3` adapter               | `<secret>`                    |
| PORT                  | The port to run the server on                                 | `8000`                        |

To run the server locally, clone the codebase and run `mix deps.get && mix run --no-halt`.

## Tests

To run the test suite, execute `mix test`.
