#[macro_use]
extern crate rustler;
extern crate image;
extern crate rustler_codegen;

use std::io::Error as IoError;
use std::io::ErrorKind as IoErrorKind;
use std::io::Write;

use image::error::ImageError;
use image::imageops::FilterType;
use image::io::Reader;
use image::{DynamicImage, GenericImageView, ImageFormat};
use rustler::resource::ResourceArc;
use rustler::types::OwnedBinary;
use rustler::{Encoder, Env, Error, Term};

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

struct ImageResource {
    pub image: DynamicImage,
    pub format: ImageFormat,
}

rustler_export_nifs!(
    "Elixir.Imagism.Native",
    [
        ("open", 1, open_image),
        ("save", 2, save_image),
        ("brighten", 2, brighten_image),
        ("blur", 2, blur_image),
        ("resize", 3, resize_image),
        ("resize_exact", 3, resize_exact_image),
        ("content_type", 1, content_type),
        ("dimensions", 1, image_dimensions),
        ("crop", 5, crop_image),
        ("encode", 1, encode_image)
    ],
    Some(on_load)
);

fn on_load(env: Env, _info: Term) -> bool {
    resource_struct_init!(ImageResource, env);

    true
}

fn image_to_term<'a>(env: Env<'a>, image: DynamicImage, format: ImageFormat) -> Term<'a> {
    ResourceArc::new(ImageResource {
        image: image,
        format: format,
    })
    .encode(env)
}

fn io_error_to_term<'a>(env: Env<'a>, err: &IoError) -> Term<'a> {
    match err.kind() {
        IoErrorKind::NotFound => atoms::enoent().encode(env),
        IoErrorKind::PermissionDenied => atoms::eacces().encode(env),
        IoErrorKind::BrokenPipe => atoms::epipe().encode(env),
        IoErrorKind::AlreadyExists => atoms::eexist().encode(env),
        _ => format!("{}", err).encode(env),
    }
}

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

fn open_image<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
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

fn save_image<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let path: String = args[1].decode()?;

    Ok(match resource.image.save(path) {
        Ok(_) => (atoms::ok(), ()).encode(env),
        Err(err) => image_error_to_term(env, &err),
    })
}

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

fn blur_image<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let sigma: f32 = args[1].decode()?;

    Ok(image_to_term(env, resource.image.blur(sigma), resource.format).encode(env))
}

fn resize_image<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let w: u32 = args[1].decode()?;
    let h: u32 = args[2].decode()?;

    Ok(image_to_term(
        env,
        resource.image.resize(w, h, FilterType::Triangle),
        resource.format,
    )
    .encode(env))
}

fn crop_image<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let x: u32 = args[1].decode()?;
    let y: u32 = args[2].decode()?;
    let w: u32 = args[3].decode()?;
    let h: u32 = args[4].decode()?;

    Ok(image_to_term(env, resource.image.crop_imm(x, y, w, h), resource.format).encode(env))
}

fn resize_exact_image<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
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

fn brighten_image<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;
    let value: i32 = args[1].decode()?;

    Ok(image_to_term(env, resource.image.brighten(value), resource.format).encode(env))
}

fn image_dimensions<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
    let resource: ResourceArc<ImageResource> = args[0].decode()?;

    Ok(resource.image.dimensions().encode(env))
}

fn encode_image<'a>(env: Env<'a>, args: &[Term<'a>]) -> Result<Term<'a>, Error> {
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
