/// A NIF for image processing using the `image` crate.
/// At the moment, this is not as fast as it should be as it
/// is doing a lot of derefering of ARCs.
#[macro_use]
extern crate rustler;
extern crate image;
extern crate rustler_codegen;

use std::io::Cursor;
use std::io::Error as IoError;
use std::io::ErrorKind as IoErrorKind;
use std::io::Write;

use image::error::ImageError;
use image::imageops::FilterType;
use image::io::Reader;
use image::{DynamicImage, GenericImageView, ImageFormat};
use rustler::resource::ResourceArc;
use rustler::types::{Binary, OwnedBinary};
use rustler::{Encoder, Env, Error, Term};

/// Contains all atoms passed back as Elixir terms.
mod atoms {
    rustler_atoms! {
        atom ok;
        atom error;

        // IO errors
        atom enoent;
        atom eacces;
        atom epipe;
        atom eexist;

        // Image errors
        atom decoding;
        atom encoding;
        atom parameter;
        atom limits;
        atom unsupported;
    }
}

/// A loaded image resource that can be processed.
struct ImageResource {
    /// The loaded image.
    pub image: DynamicImage,

    /// The original format that the image was loaded in.
    pub format: ImageFormat,
}

rustler_export_nifs!(
    "Elixir.Imagism.Native",
    [
        ("open", 1, open),
        ("brighten", 2, brighten),
        ("contrast", 2, contrast),
        ("blur", 2, blur),
        ("resize", 3, resize),
        ("content_type", 1, content_type),
        ("dimensions", 1, dimensions),
        ("flipv", 1, flipv),
        ("fliph", 1, fliph),
        ("rotate", 2, rotate),
        ("crop", 5, crop),
        ("encode", 1, encode),
        ("decode", 1, decode)
    ],
    Some(on_load)
);

/// Initialises the NIF.
fn on_load(env: Env, _info: Term) -> bool {
    resource_struct_init!(ImageResource, env);

    true
}

/// Converts a loaded image to an ARC wrapped as an Elixir term.
fn image_to_term<'a>(env: Env<'a>, image: DynamicImage, format: ImageFormat) -> Term<'a> {
    ResourceArc::new(ImageResource {
        image: image,
        format: format,
    })
    .encode(env)
}

/// Converts an IoError to a Elixir term.
fn io_error_to_term<'a>(env: Env<'a>, err: &IoError) -> Term<'a> {
    match err.kind() {
        IoErrorKind::NotFound => atoms::enoent().encode(env),
        IoErrorKind::PermissionDenied => atoms::eacces().encode(env),
        IoErrorKind::BrokenPipe => atoms::epipe().encode(env),
        IoErrorKind::AlreadyExists => atoms::eexist().encode(env),
        _ => format!("{}", err).encode(env),
    }
}

/// Converts an ImageError to an Elixir term.
fn image_error_to_term<'a>(env: Env<'a>, err: &ImageError) -> Term<'a> {
    (
        atoms::error(),
        match err {
            ImageError::Decoding(_) => atoms::decoding().encode(env),
            ImageError::Encoding(_) => atoms::encoding().encode(env),
            ImageError::Parameter(_) => atoms::parameter().encode(env),
            ImageError::Limits(_) => atoms::limits().encode(env),
            ImageError::Unsupported(_) => atoms::unsupported().encode(env),
            ImageError::IoError(io_error) => io_error_to_term(env, &io_error),
        },
    )
        .encode(env)
}

/// Opens an image from a specific file path.
/// Generally it's best to pass in an absolute path.
fn open<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let path: String = args[0].decode()?;

    match Reader::open(path) {
        Ok(reader) => {
            let format = reader.format().unwrap_or(ImageFormat::Jpeg);

            Ok(match reader.decode() {
                Ok(image) => (atoms::ok(), image_to_term(env, image, format)).encode(env),
                Err(err) => image_error_to_term(env, &err),
            })
        }
        Err(err) => Ok((atoms::error(), io_error_to_term(env, &err)).encode(env)),
    }
}

/// Returns the original content type of the image.
fn content_type<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;

    Ok(match resource.format {
        ImageFormat::Png => "image/png",
        ImageFormat::Gif => "image/gif",
        ImageFormat::Ico => "image/vnd.microsoft.icon",
        ImageFormat::Tiff => "image/tiff",
        ImageFormat::Bmp => "image/bmp",
        _ => "image/jpeg",
    }
    .encode(env))
}

/// Blurs an image by a sigma.
fn blur<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let sigma: f32 = args[1].decode()?;

    Ok(image_to_term(env, resource.image.blur(sigma), resource.format).encode(env))
}

/// Rotates an image by 90, 180 or 270 degrees.
/// If the rotation amount doesn't match either of those three
/// then the image is ketp alone.
fn rotate<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let rotation: u32 = args[1].decode()?;

    if rotation != 90 && rotation != 180 && rotation != 270 {
        return Ok(resource.encode(env));
    }

    let rotated = match rotation {
        90 => resource.image.rotate90(),
        180 => resource.image.rotate180(),
        _ => resource.image.rotate270(),
    };

    Ok(image_to_term(env, rotated, resource.format).encode(env))
}

/// Crops an image at a point in certain dimensions.
fn crop<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let x: u32 = args[1].decode()?;
    let y: u32 = args[2].decode()?;
    let w: u32 = args[3].decode()?;
    let h: u32 = args[4].decode()?;

    Ok(image_to_term(env, resource.image.crop_imm(x, y, w, h), resource.format).encode(env))
}

/// Resizes an image to exact dimensions.
fn resize<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let w: u32 = args[1].decode()?;
    let h: u32 = args[2].decode()?;

    Ok(image_to_term(
        env,
        resource.image.resize_exact(w, h, FilterType::Triangle),
        resource.format,
    )
    .encode(env))
}

/// Brightens an image by a constant.
fn brighten<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let value: i32 = args[1].decode()?;

    Ok(image_to_term(env, resource.image.brighten(value), resource.format).encode(env))
}

/// Adjusts the contrast of an image by a constant.
fn contrast<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let value: f32 = args[1].decode()?;

    Ok(image_to_term(env, resource.image.adjust_contrast(value), resource.format).encode(env))
}

/// Flips an image vertically.
fn flipv<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;

    Ok(image_to_term(env, resource.image.flipv(), resource.format).encode(env))
}

/// Flips an image horizontally.
fn fliph<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;

    Ok(image_to_term(env, resource.image.fliph(), resource.format).encode(env))
}

/// Returns the dimensions of the image.
fn dimensions<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;

    Ok(resource.image.dimensions().encode(env))
}

/// Encodes an image to an Elixir binary string.
fn encode<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let mut vec: Vec<u8> = Vec::new();

    Ok(match resource.image.write_to(&mut vec, resource.format) {
        Ok(_) => {
            let mut bin = OwnedBinary::new(vec.len()).unwrap();

            bin.as_mut_slice().write_all(&vec).unwrap();
            (atoms::ok(), bin.release(env)).encode(env)
        }
        Err(err) => image_error_to_term(env, &err),
    })
}

/// Decodes an image from an Elixir binary string.
fn decode<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let bin: Binary<'a> = args[0].decode()?;

    Ok(
        match Reader::new(Cursor::new(bin.as_slice())).with_guessed_format() {
            Ok(reader) => {
                let format = reader.format().unwrap_or(ImageFormat::Jpeg);

                match reader.decode() {
                    Ok(image) => (atoms::ok(), image_to_term(env, image, format)).encode(env),
                    Err(err) => image_error_to_term(env, &err),
                }
            }
            Err(err) => (atoms::error(), io_error_to_term(env, &err)).encode(env),
        },
    )
}
