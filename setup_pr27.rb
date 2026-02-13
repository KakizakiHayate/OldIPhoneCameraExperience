#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'OldIPhoneCameraExperience.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Helper to find or create group with path
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

# Remove existing file references first (to fix doubled paths)
def remove_file_ref(project, filename)
  project.files.each do |file_ref|
    if file_ref.path&.include?(filename)
      # Remove from build phases
      project.targets.each do |target|
        target.source_build_phase.files.each do |build_file|
          if build_file.file_ref == file_ref
            build_file.remove_from_project
            puts "  Removed build file for #{filename} from #{target.name}"
          end
        end
      end
      # Remove file reference
      file_ref.remove_from_project
      puts "  Removed file ref: #{file_ref.path}"
    end
  end
end

# Helper to add file to group and target with just filename
def add_file_to_target(project, group, filename, full_path, target_name)
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

# Clean up existing refs
puts "Cleaning up existing references..."
remove_file_ref(project, 'CameraViewModel.swift')
remove_file_ref(project, 'CameraViewModelTests.swift')

# 1. Add CameraViewModel.swift to main target
puts "\nAdding CameraViewModel.swift..."
vm_group = find_or_create_group(project, ['OldIPhoneCameraExperience', 'ViewModels'])
add_file_to_target(
  project, vm_group,
  'CameraViewModel.swift',
  'OldIPhoneCameraExperience/ViewModels/CameraViewModel.swift',
  'OldIPhoneCameraExperience'
)

# 2. Add CameraViewModelTests.swift to test target
puts "\nAdding CameraViewModelTests.swift..."
vm_test_group = find_or_create_group(project, ['OldIPhoneCameraExperienceTests', 'ViewModels'])
add_file_to_target(
  project, vm_test_group,
  'CameraViewModelTests.swift',
  'OldIPhoneCameraExperienceTests/ViewModels/CameraViewModelTests.swift',
  'OldIPhoneCameraExperienceTests'
)

project.save
puts "\nDone! Project saved."
