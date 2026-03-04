#!/usr/bin/env python3
"""Generate Paletto.xcodeproj/project.pbxproj"""
import uuid
import os

def gen_id():
    return uuid.uuid4().hex[:24].upper()

# Collect all Swift source files
source_root = "Paletto"
swift_files = []
for root, dirs, files in os.walk(source_root):
    for f in files:
        if f.endswith('.swift'):
            rel = os.path.relpath(os.path.join(root, f), source_root)
            swift_files.append((f, rel))

swift_files.sort(key=lambda x: x[1])

# Generate IDs
project_id = gen_id()
main_group_id = gen_id()
products_group_id = gen_id()
app_product_id = gen_id()
target_id = gen_id()
build_config_list_project_id = gen_id()
build_config_list_target_id = gen_id()
debug_config_project_id = gen_id()
release_config_project_id = gen_id()
debug_config_target_id = gen_id()
release_config_target_id = gen_id()
sources_phase_id = gen_id()
resources_phase_id = gen_id()
frameworks_phase_id = gen_id()

# Source group structure
source_group_id = gen_id()  # Paletto folder
app_group_id = gen_id()
core_group_id = gen_id()
models_group_id = gen_id()
services_group_id = gen_id()
protocols_group_id = gen_id()
extensions_group_id = gen_id()
utilities_group_id = gen_id()
features_group_id = gen_id()
resources_group_id = gen_id()
assets_ref_id = gen_id()
info_plist_ref_id = gen_id()

# Feature subgroups
feature_names = ["PaletteExtraction", "PaletteDetail", "PaletteList",
                 "ColorPicker", "ContrastChecker", "Export", "Settings"]
feature_group_ids = {n: gen_id() for n in feature_names}

# File references and build files
file_refs = {}
build_files = {}
for name, path in swift_files:
    fref = gen_id()
    bfile = gen_id()
    file_refs[path] = fref
    build_files[path] = bfile

# Tests
tests_group_id = gen_id()
test_target_id = gen_id()
test_product_id = gen_id()
test_build_config_list_id = gen_id()
test_debug_config_id = gen_id()
test_release_config_id = gen_id()
test_sources_phase_id = gen_id()
test_dep_id = gen_id()
test_dep_proxy_id = gen_id()

# Helper to categorize files into groups
def get_group(path):
    if path.startswith("App/"): return "app"
    if path.startswith("Core/Models/"): return "models"
    if path.startswith("Core/Services/Protocols/"): return "protocols"
    if path.startswith("Core/Extensions/"): return "extensions"
    if path.startswith("Core/Utilities/"): return "utilities"
    for fn in feature_names:
        if path.startswith(f"Features/{fn}/"): return f"feature_{fn}"
    return "source"

groups = {}
for name, path in swift_files:
    g = get_group(path)
    groups.setdefault(g, []).append(path)

def file_ref_section():
    lines = []
    for name, path in swift_files:
        fid = file_refs[path]
        lines.append(f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{name}"; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{assets_ref_id} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{info_plist_ref_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
    lines.append(f'\t\t{app_product_id} /* Paletto.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Paletto.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    return "\n".join(lines)

def build_file_section():
    lines = []
    for name, path in swift_files:
        bid = build_files[path]
        fid = file_refs[path]
        lines.append(f'\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};')
    return "\n".join(lines)

def group_children(group_name):
    paths = groups.get(group_name, [])
    return ",\n".join([f'\t\t\t\t{file_refs[p]} /* {os.path.basename(p)} */' for p in sorted(paths)])

NL = "\n"

# Pre-build joined strings to avoid backslash in f-strings
feature_children_str = NL.join([f'\t\t\t\t{feature_group_ids[n]} /* {n} */,' for n in feature_names])

feature_groups_str = NL.join([
    f'\t\t{feature_group_ids[n]} /* {n} */ = {{\n'
    f'\t\t\tisa = PBXGroup;\n'
    f'\t\t\tchildren = (\n'
    f'{group_children(f"feature_{n}")}\n'
    f'\t\t\t);\n'
    f'\t\t\tpath = {n};\n'
    f'\t\t\tsourceTree = "<group>";\n'
    f'\t\t}};'
    for n in feature_names
])

source_build_files_str = NL.join([
    f'\t\t\t\t{build_files[p]} /* {os.path.basename(p)} in Sources */,'
    for _, p in swift_files
])

pbxproj = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{build_file_section()}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{file_ref_section()}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_phase_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{source_group_id} /* Paletto */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_product_id} /* Paletto.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{source_group_id} /* Paletto */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_group_id} /* App */,
\t\t\t\t{core_group_id} /* Core */,
\t\t\t\t{features_group_id} /* Features */,
\t\t\t\t{resources_group_id} /* Resources */,
\t\t\t);
\t\t\tpath = Paletto;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{app_group_id} /* App */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{group_children("app")}
\t\t\t);
\t\t\tpath = App;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{core_group_id} /* Core */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{models_group_id} /* Models */,
\t\t\t\t{services_group_id} /* Services */,
\t\t\t\t{extensions_group_id} /* Extensions */,
\t\t\t\t{utilities_group_id} /* Utilities */,
\t\t\t);
\t\t\tpath = Core;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{models_group_id} /* Models */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{group_children("models")}
\t\t\t);
\t\t\tpath = Models;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{services_group_id} /* Services */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{protocols_group_id} /* Protocols */,
\t\t\t);
\t\t\tpath = Services;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{protocols_group_id} /* Protocols */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{group_children("protocols")}
\t\t\t);
\t\t\tpath = Protocols;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{extensions_group_id} /* Extensions */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{group_children("extensions")}
\t\t\t);
\t\t\tpath = Extensions;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{utilities_group_id} /* Utilities */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{group_children("utilities")}
\t\t\t);
\t\t\tpath = Utilities;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{features_group_id} /* Features */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{feature_children_str}
\t\t\t);
\t\t\tpath = Features;
\t\t\tsourceTree = "<group>";
\t\t}};
{feature_groups_str}
\t\t{resources_group_id} /* Resources */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{assets_ref_id} /* Assets.xcassets */,
\t\t\t\t{info_plist_ref_id} /* Info.plist */,
\t\t\t);
\t\t\tpath = Resources;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_id} /* Paletto */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {build_config_list_target_id} /* Build configuration list for PBXNativeTarget "Paletto" */;
\t\t\tbuildPhases = (
\t\t\t\t{sources_phase_id} /* Sources */,
\t\t\t\t{frameworks_phase_id} /* Frameworks */,
\t\t\t\t{resources_phase_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = Paletto;
\t\t\tproductName = Paletto;
\t\t\tproductReference = {app_product_id} /* Paletto.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{project_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1500;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t}};
\t\t\tbuildConfigurationList = {build_config_list_project_id} /* Build configuration list for PBXProject "Paletto" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{target_id} /* Paletto */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_phase_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_phase_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{source_build_files_str}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{debug_config_project_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_config_project_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{debug_config_target_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Paletto/Resources/Info.plist;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.paletto.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{release_config_target_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Paletto/Resources/Info.plist;
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.paletto.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{build_config_list_project_id} /* Build configuration list for PBXProject "Paletto" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_config_project_id} /* Debug */,
\t\t\t\t{release_config_project_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{build_config_list_target_id} /* Build configuration list for PBXNativeTarget "Paletto" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{debug_config_target_id} /* Debug */,
\t\t\t\t{release_config_target_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {project_id} /* Project object */;
}}
"""

output_path = "Paletto.xcodeproj/project.pbxproj"
os.makedirs(os.path.dirname(output_path), exist_ok=True)
with open(output_path, 'w') as f:
    f.write(pbxproj)

print(f"Generated {output_path}")
print(f"  {len(swift_files)} Swift files")

