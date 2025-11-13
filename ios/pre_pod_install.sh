#!/bin/bash
set -e

echo "🔧 Installing xcodeproj gem..."
gem install xcodeproj

echo "🔧 Fixing HomeWidget dependency..."

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

# Add dependency
existing = runner_target.dependencies.find { |dep| dep.target == widget_target }
unless existing
  puts "➕ Adding HomeWidget dependency..."
  runner_target.add_dependency(widget_target)
end

# Fix build phase ordering
embed_phase = runner_target.copy_files_build_phases.find do |phase|
  phase.name == 'Embed App Extensions'
end

thin_binary_phase = runner_target.shell_script_build_phases.find do |phase|
  phase.name == 'Thin Binary'
end

if embed_phase && thin_binary_phase
  other_phases = runner_target.build_phases.reject do |phase|
    phase == embed_phase || phase == thin_binary_phase
  end
  
  runner_target.build_phases.clear
  other_phases.each { |phase| runner_target.build_phases << phase }
  runner_target.build_phases << thin_binary_phase
  runner_target.build_phases << embed_phase
  
  puts "✅ Reordered build phases"
end

project.save
puts "✅ Configuration complete!"
EOF

ruby fix_dependency.rb
rm fix_dependency.rb

echo "✅ Pre-install complete!"