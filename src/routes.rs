use std::path::Path;

use axum::Router;
use mime::TEXT_PLAIN_UTF_8;
use tower_http::services::{ServeDir, ServeFile};

use crate::by::By;

pub fn router<D: AsRef<Path>, S: AsRef<Path>>(directory: D, script: S) -> Router {
    let serve_static = ServeDir::new(directory);
    let serve_script = ServeFile::new_with_mime(script, TEXT_PLAIN_UTF_8.by_ref());

    Router::new()
        .route_service("/", serve_script)
        .nest_service("/static", serve_static)
}
