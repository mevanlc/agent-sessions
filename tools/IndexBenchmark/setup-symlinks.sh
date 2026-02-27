#!/bin/bash
# Creates SharedSources/ symlinks pointing at the main project's Swift files.
# Run once after clone: cd Tools/IndexBenchmark && bash setup-symlinks.sh

set -euo pipefail
cd "$(dirname "$0")"

ROOT="../../AgentSessions"

mkdir -p SharedSources/{Indexing,Model,Search,Services,Utilities,Support}

# Indexing
ln -sf "../../$ROOT/Indexing/AnalyticsIndexer.swift"       SharedSources/Indexing/
ln -sf "../../$ROOT/Indexing/DB.swift"                      SharedSources/Indexing/
ln -sf "../../$ROOT/Indexing/SessionMetaRepository.swift"   SharedSources/Indexing/

# Model
ln -sf "../../$ROOT/Model/Session.swift"                    SharedSources/Model/
ln -sf "../../$ROOT/Model/SessionEvent.swift"               SharedSources/Model/
ln -sf "../../$ROOT/Model/SessionSource.swift"              SharedSources/Model/

# Search
ln -sf "../../$ROOT/Search/SessionSearchTextBuilder.swift"  SharedSources/Search/

# Services — parsers
ln -sf "../../$ROOT/Services/CodexSessionParser.swift"      SharedSources/Services/
ln -sf "../../$ROOT/Services/ClaudeSessionParser.swift"     SharedSources/Services/
ln -sf "../../$ROOT/Services/GeminiSessionParser.swift"     SharedSources/Services/
ln -sf "../../$ROOT/Services/OpenCodeSessionParser.swift"   SharedSources/Services/
ln -sf "../../$ROOT/Services/CopilotSessionParser.swift"    SharedSources/Services/
ln -sf "../../$ROOT/Services/DroidSessionParser.swift"      SharedSources/Services/
ln -sf "../../$ROOT/Services/ToolTextBlockNormalizer.swift"  SharedSources/Services/
ln -sf "../../$ROOT/Services/GeminiHashResolver.swift"      SharedSources/Services/

# Services — discovery
ln -sf "../../$ROOT/Services/SessionDiscovery.swift"        SharedSources/Services/
ln -sf "../../$ROOT/Services/GeminiSessionDiscovery.swift"  SharedSources/Services/
ln -sf "../../$ROOT/Services/OpenCodeSessionDiscovery.swift" SharedSources/Services/
ln -sf "../../$ROOT/Services/DroidSessionDiscovery.swift"   SharedSources/Services/
ln -sf "../../$ROOT/Services/OpenClawSessionDiscovery.swift" SharedSources/Services/

# Utilities
ln -sf "../../$ROOT/Utilities/JSONLReader.swift"            SharedSources/Utilities/

# Support
ln -sf "../../$ROOT/Support/FeatureFlags.swift"             SharedSources/Support/
ln -sf "../../$ROOT/Support/AppRuntime.swift"               SharedSources/Support/
ln -sf "../../$ROOT/ClaudeStatus/ClaudeProbeConfig.swift"   SharedSources/Support/
ln -sf "../../$ROOT/CodexStatus/CodexProbeConfig.swift"     SharedSources/Support/

echo "Symlinks created in SharedSources/"
