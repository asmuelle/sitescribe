# SiteScribe — offline-first AI field-documentation copilot (iOS).
# Single source of truth for commands. Agents and humans use `just`, never raw xcodebuild.

app := "SiteScribe"
sim := "iPhone 16"

# List all recipes
default:
    @just --list --unsorted

# Generate the Xcode project via XcodeGen and resolve SPM dependencies
bootstrap:
    @if [ ! -f project.yml ]; then \
        echo "Not bootstrapped: project.yml is missing."; \
        echo "Write the XcodeGen spec first: app target '{{app}}', iOS 26 deployment target,"; \
        echo "local SPM packages under Packages/. See DESIGN.md milestone M0."; \
        exit 1; \
    fi
    @command -v xcodegen >/dev/null 2>&1 || { echo "xcodegen not found. Install: brew install xcodegen"; exit 1; }
    xcodegen generate
    xcodebuild -resolvePackageDependencies -project "{{app}}.xcodeproj" -scheme "{{app}}"

# Resolve the simulator: prefer {{sim}}, else fall back to the first available iPhone
_sim:
    @if xcrun simctl list devices available | grep -q "{{sim}} ("; then \
        echo "{{sim}}"; \
    else \
        xcrun simctl list devices available | grep -E '^ +iPhone' | head -1 | sed -E 's/^ +//; s/ \(.*$//'; \
    fi

# Build the app for the iOS Simulator (scheme SiteScribe)
build:
    @if [ ! -d "{{app}}.xcodeproj" ]; then \
        echo "Not bootstrapped: {{app}}.xcodeproj is missing."; \
        echo "Run 'just bootstrap' (needs project.yml — see DESIGN.md milestone M0)."; \
        exit 1; \
    fi
    sim_name="$(just _sim)" && xcodebuild build -project "{{app}}.xcodeproj" -scheme "{{app}}" \
        -destination "platform=iOS Simulator,name=$sim_name" \
        CODE_SIGNING_ALLOWED=NO

# Run tests on the iPhone 16 simulator (falls back to the first available iPhone)
test:
    @if [ ! -d "{{app}}.xcodeproj" ]; then \
        echo "Not bootstrapped: {{app}}.xcodeproj is missing."; \
        echo "Run 'just bootstrap' (needs project.yml — see DESIGN.md milestone M0)."; \
        exit 1; \
    fi
    sim_name="$(just _sim)" && xcodebuild test -project "{{app}}.xcodeproj" -scheme "{{app}}" \
        -destination "platform=iOS Simulator,name=$sim_name" \
        CODE_SIGNING_ALLOWED=NO

# Lint all Swift sources with SwiftLint (skips gracefully when not installed)
lint:
    @if ! command -v swiftlint >/dev/null 2>&1; then \
        echo "swiftlint not installed — skipping lint (brew install swiftlint to enable)."; \
    elif [ -z "$(find . -name '*.swift' -not -path './.build/*' -print -quit)" ]; then \
        echo "Not bootstrapped: no Swift sources yet — nothing to lint."; \
        echo "Create the app shell and packages first (DESIGN.md milestone M0)."; \
        exit 1; \
    else \
        swiftlint lint --quiet; \
    fi

# Format all Swift sources in place with swiftformat
format:
    @command -v swiftformat >/dev/null 2>&1 || { echo "swiftformat not found. Install: brew install swiftformat"; exit 1; }
    @if [ -z "$(find . -name '*.swift' -not -path './.build/*' -print -quit)" ]; then \
        echo "Not bootstrapped: no Swift sources yet — nothing to format."; \
        echo "Create the app shell and packages first (DESIGN.md milestone M0)."; \
        exit 1; \
    fi
    swiftformat .

# Full local gate: lint + build + test (what CI runs once bootstrapped)
ci: lint build test
