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

# Add dependency
existing = runner_target.dependencies.find { |dep| dep.target == widget_target }
unless existing
  puts "➕ Adding HomeWidget dependency..."
  runner_target.add_dependency(widget_target)
end

# Find the Thin Binary script phase
thin_binary = runner_target.shell_script_build_phases.find do |phase|
  phase.name == 'Thin Binary'
end

if thin_binary
  puts "🔧 Fixing Thin Binary script phase..."
  
  # Clear input and output paths that cause the cycle
  thin_binary.input_paths.clear
  thin_binary.output_paths.clear
  
  # Set to run on every build to prevent issues
  thin_binary.always_out_of_date = true
  
  puts "✅ Cleared input/output paths from Thin Binary"
end

# Reorder build phases
embed_extensions = runner_target.copy_files_build_phases.find do |phase|
  phase.name == 'Embed App Extensions'
end

if thin_binary && embed_extensions
  # Remove both phases
  runner_target.build_phases.delete(thin_binary)
  runner_target.build_phases.delete(embed_extensions)
  
  # Find the position to insert (before the last phase)
  insert_position = runner_target.build_phases.length
  
  # Re-add Thin Binary before Embed App Extensions
  runner_target.build_phases.insert(insert_position, thin_binary)
  runner_target.build_phases.insert(insert_position + 1, embed_extensions)
  
  puts "✅ Reordered: Thin Binary comes before Embed App Extensions"
end

puts "\n📋 Final build phase order:"
runner_target.build_phases.each_with_index do |phase, idx|
  puts "  #{idx}: #{phase.display_name}"
end

project.save
puts "\n✅ Configuration complete!"
EOF

ruby fix_dependency.rb
rm fix_dependency.rb

echo "✅ Pre-install script complete!"