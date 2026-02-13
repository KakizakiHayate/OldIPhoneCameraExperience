#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'OldIPhoneCameraExperience.xcodeproj'
project = Xcodeproj::Project.open(project_path)

def find_or_create_group(project, path_components)
  current = project.main_group
  path_components.each do |component|
    found = current.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.name == component }
    if found
      current = found
    else
      current = current.new_group(component, component)
      puts "  Created group: #{component}"
    end
  end
  current
end

def add_file_to_target(project, group, filename, target_name)
  existing = group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXFileReference) && c.path == filename }
  if existing
    puts "  Already exists: #{filename}"
    return
  end
  file_ref = group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target = project.targets.find { |t| t.name == target_name }
  if target
    target.source_build_phase.add_file_reference(file_ref)
    puts "  Added #{filename} to #{target_name}"
  else
    puts "  WARNING: Target '#{target_name}' not found"
  end
end

# UI Component files
ui_files = [
  'ShutterButton.swift',
  'IrisAnimationView.swift',
  'ToolbarButton.swift',
  'ThumbnailView.swift'
]

puts "Adding UI Component files..."
components_group = find_or_create_group(project, ['OldIPhoneCameraExperience', 'Views', 'Components'])

ui_files.each do |filename|
  add_file_to_target(project, components_group, filename, 'OldIPhoneCameraExperience')
end

project.save
puts "\nDone! Project saved."
