#!/bin/bash
set -e

echo "🔧 Installing xcodeproj gem..."
gem install xcodeproj

echo "🔧 Fixing HomeWidget dependency and build phases..."

cat > fix_dependency.rb << 'EOF'
require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

runner_target = project.targets.find { |t| t.name == 'Runner' }
widget_target = project.targets.find { |t| t.name == 'HomeWidget' }

if runner_target.nil? || widget_target.nil?
  puts "❌ Error: Targets not found"
  exit 1
end

puts "📋 Current build phases:"
runner_target.build_phases.each_with_index do |phase, idx|
  puts "  #{idx}: #{phase.display_name}"
end

# Add dependency
existing = runner_target.dependencies.find { |dep| dep.target == widget_target }
unless existing
  puts "➕ Adding HomeWidget dependency..."
  runner_target.add_dependency(widget_target)
end

# Find all build phases
sources_phase = runner_target.source_build_phase
frameworks_phase = runner_target.frameworks_build_phase
resources_phase = runner_target.resources_build_phase

embed_frameworks = runner_target.copy_files_build_phases.find do |phase|
  phase.name == 'Embed Frameworks'
end

embed_extensions = runner_target.copy_files_build_phases.find do |phase|
  phase.name == 'Embed App Extensions'
end

thin_binary = runner_target.shell_script_build_phases.find do |phase|
  phase.name == 'Thin Binary'
end

run_script = runner_target.shell_script_build_phases.find do |phase|
  phase.name == 'Run Script'
end

other_scripts = runner_target.shell_script_build_phases.reject do |phase|
  phase.name == 'Thin Binary' || phase.name == 'Run Script'
end

other_copy = runner_target.copy_files_build_phases.reject do |phase|
  phase.name == 'Embed Frameworks' || phase.name == 'Embed App Extensions'
end

# Clear and rebuild in correct order
runner_target.build_phases.clear

puts "\n🔧 Rebuilding build phases in correct order..."

# 1. Run Script (Flutter build)
runner_target.build_phases << run_script if run_script
puts "  1. Run Script"

# 2. Sources
runner_target.build_phases << sources_phase if sources_phase
puts "  2. Sources"

# 3. Frameworks
runner_target.build_phases << frameworks_phase if frameworks_phase
puts "  3. Frameworks"

# 4. Resources
runner_target.build_phases << resources_phase if resources_phase
puts "  4. Resources"

# 5. Other copy phases (except Embed Extensions)
other_copy.each do |phase|
  runner_target.build_phases << phase
  puts "  5. #{phase.display_name}"
end

# 6. Embed Frameworks
runner_target.build_phases << embed_frameworks if embed_frameworks
puts "  6. Embed Frameworks"

# 7. Other scripts (CocoaPods scripts, etc.)
other_scripts.each do |phase|
  runner_target.build_phases << phase
  puts "  7. #{phase.display_name}"
end

# 8. Thin Binary (MUST come before Embed App Extensions)
runner_target.build_phases << thin_binary if thin_binary
puts "  8. Thin Binary"

# 9. Embed App Extensions (LAST)
runner_target.build_phases << embed_extensions if embed_extensions
puts "  9. Embed App Extensions"

puts "\n✅ Final build phase order:"
runner_target.build_phases.each_with_index do |phase, idx|
  puts "  #{idx}: #{phase.display_name}"
end

project.save
puts "\n✅ Configuration complete!"
EOF

ruby fix_dependency.rb
rm fix_dependency.rb

echo "✅ Pre-install script complete!"