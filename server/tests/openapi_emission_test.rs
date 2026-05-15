/// Integration test: verifies the `--emit-openapi` contract programmatically.
///
/// Run explicitly with:
///   cargo test --test openapi_emission_test -- --nocapture
///
/// The test spawns a *nested* `cargo run --bin iter-server -- --emit-openapi` so
/// it redirects the child's CARGO_TARGET_DIR to CARGO_TARGET_TMPDIR (provided
/// free-of-charge by Cargo for every integration-test crate) to avoid the
/// cargo-lock conflict that would arise if both parent and child fight over the
/// same target directory.
#[test]
fn emit_openapi_contract() {
    // CARGO_TARGET_TMPDIR  →  e.g. .../target/tmp/<test-name>/
    // CARGO_MANIFEST_DIR   →  .../server/
    // CARGO                →  the exact cargo binary driving the parent build
    let cargo = env!("CARGO");
    let manifest_dir = env!("CARGO_MANIFEST_DIR");
    let target_tmpdir = env!("CARGO_TARGET_TMPDIR");

    let output = std::process::Command::new(cargo)
        .args(["run", "--quiet", "--bin", "iter-server", "--", "--emit-openapi"])
        .env("CARGO_TARGET_DIR", target_tmpdir)
        // Suppress any database chatter on stderr
        .env("DATABASE_URL", "")
        .current_dir(manifest_dir)
        .output()
        .expect("failed to spawn child `cargo run`");

    assert!(
        output.status.success(),
        "child process exited non-zero:\nstderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    let stdout = String::from_utf8(output.stdout).expect("stdout is not valid UTF-8");

    let json: serde_json::Value =
        serde_json::from_str(&stdout).expect("stdout is not valid JSON");

    // 1. `openapi` field exists and starts with "3."
    let openapi_version = json["openapi"]
        .as_str()
        .expect("`openapi` field missing or not a string");
    assert!(
        openapi_version.starts_with("3."),
        "expected OpenAPI 3.x, got: {openapi_version}"
    );

    // 2. info.title == "ITER API"
    assert_eq!(
        json["info"]["title"],
        serde_json::Value::String("ITER API".to_string()),
        "info.title mismatch"
    );

    // 3. paths./health.get.operationId == "health"
    assert_eq!(
        json["paths"]["/health"]["get"]["operationId"],
        serde_json::Value::String("health".to_string()),
        "operationId mismatch"
    );

    // 4. paths./health.get.tags[0] == "system"
    assert_eq!(
        json["paths"]["/health"]["get"]["tags"][0],
        serde_json::Value::String("system".to_string()),
        "first tag mismatch"
    );

    // 5. components.schemas.HealthResponse exists (non-null)
    assert!(
        !json["components"]["schemas"]["HealthResponse"].is_null(),
        "components.schemas.HealthResponse is missing"
    );
}
