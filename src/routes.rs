use std::path::Path;

use axum::{
    Router,
    http::{HeaderValue, header::CACHE_CONTROL},
};
use mime::TEXT_PLAIN_UTF_8;
use tower_http::{
    services::{ServeDir, ServeFile},
    set_header::SetResponseHeaderLayer,
};

use crate::by::By;

pub const NO_CACHE: HeaderValue = HeaderValue::from_static("no-cache");

pub fn router<D: AsRef<Path>, S: AsRef<Path>>(directory: D, script: S) -> Router {
    let no_cache_layer = SetResponseHeaderLayer::overriding(CACHE_CONTROL, NO_CACHE);

    let serve_script = ServeFile::new_with_mime(script, TEXT_PLAIN_UTF_8.by_ref());

    let serve_static = ServeDir::new(directory);

    Router::new()
        .route_service("/", serve_script)
        .route_layer(no_cache_layer) // do not cache `install.sh` script at `/`
        .nest_service("/static", serve_static)
}
