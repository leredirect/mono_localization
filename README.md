**MONO LOCALIZATION**   
This package helps you to create overridable localization libraries for mono repository  .
Example:  
provide this config to your pubspec.yaml:

    mono_localization:  
      enabled: true  
      base_class_path: lib/test/library_base.dart  
      base_class_name: LocalizationLibraryBase  
      structure:  
        - library:  
            library_name: BaseLibrary  
            base: true  
            arb_dir: lib/test/base_library/arb/  
            output_dir: lib/test/base_library/  
            widget_path: lib/test/base_library/base_library_localization_provider.dart  
            widget_name: BaseLibraryLocalizationProvider  
        - library:  
            library_name: OtherBaseLibrary  
            base: true  
            arb_dir: lib/test/other_base_library/arb/  
            output_dir: lib/test/other_base_library/  
            widget_path: lib/test/other_base_library/other_base_library_localization_provider.dart  
            widget_name: OtherBaseLibraryLocalizationProvider  
        - library:  
            library_name: NonBaseLibrary  
            arb_dir: lib/test/non_base_library/arb/  
            output_dir: lib/test/non_base_library/  
            widget_path: lib/test/non_base_library/non_base_library_localization_provider.dart  
            widget_name: NonBaseLibraryLocalizationProvider

Run `dart run mono_localization:generate` in order to generate or update strings.