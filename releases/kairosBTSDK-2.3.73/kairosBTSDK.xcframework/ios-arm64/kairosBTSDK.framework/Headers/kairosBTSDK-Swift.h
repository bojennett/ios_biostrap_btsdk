#if 0
#elif defined(__arm64__) && __arm64__
// Generated by Apple Swift version 5.9.2 (swiftlang-5.9.2.2.56 clang-1500.1.0.2.5)
#ifndef KAIROSBTSDK_SWIFT_H
#define KAIROSBTSDK_SWIFT_H
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgcc-compat"

#if !defined(__has_include)
# define __has_include(x) 0
#endif
#if !defined(__has_attribute)
# define __has_attribute(x) 0
#endif
#if !defined(__has_feature)
# define __has_feature(x) 0
#endif
#if !defined(__has_warning)
# define __has_warning(x) 0
#endif

#if __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#if defined(__OBJC__)
#include <Foundation/Foundation.h>
#endif
#if defined(__cplusplus)
#include <cstdint>
#include <cstddef>
#include <cstdbool>
#include <cstring>
#include <stdlib.h>
#include <new>
#include <type_traits>
#else
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#endif
#if defined(__cplusplus)
#if defined(__arm64e__) && __has_include(<ptrauth.h>)
# include <ptrauth.h>
#else
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreserved-macro-identifier"
# ifndef __ptrauth_swift_value_witness_function_pointer
#  define __ptrauth_swift_value_witness_function_pointer(x)
# endif
# ifndef __ptrauth_swift_class_method_pointer
#  define __ptrauth_swift_class_method_pointer(x)
# endif
#pragma clang diagnostic pop
#endif
#endif

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus)
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...) 
# endif
#endif
#if !defined(SWIFT_RUNTIME_NAME)
# if __has_attribute(objc_runtime_name)
#  define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
# else
#  define SWIFT_RUNTIME_NAME(X) 
# endif
#endif
#if !defined(SWIFT_COMPILE_NAME)
# if __has_attribute(swift_name)
#  define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
# else
#  define SWIFT_COMPILE_NAME(X) 
# endif
#endif
#if !defined(SWIFT_METHOD_FAMILY)
# if __has_attribute(objc_method_family)
#  define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
# else
#  define SWIFT_METHOD_FAMILY(X) 
# endif
#endif
#if !defined(SWIFT_NOESCAPE)
# if __has_attribute(noescape)
#  define SWIFT_NOESCAPE __attribute__((noescape))
# else
#  define SWIFT_NOESCAPE 
# endif
#endif
#if !defined(SWIFT_RELEASES_ARGUMENT)
# if __has_attribute(ns_consumed)
#  define SWIFT_RELEASES_ARGUMENT __attribute__((ns_consumed))
# else
#  define SWIFT_RELEASES_ARGUMENT 
# endif
#endif
#if !defined(SWIFT_WARN_UNUSED_RESULT)
# if __has_attribute(warn_unused_result)
#  define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
# else
#  define SWIFT_WARN_UNUSED_RESULT 
# endif
#endif
#if !defined(SWIFT_NORETURN)
# if __has_attribute(noreturn)
#  define SWIFT_NORETURN __attribute__((noreturn))
# else
#  define SWIFT_NORETURN 
# endif
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA 
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA 
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA 
#endif
#if !defined(SWIFT_CLASS)
# if __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif
#if !defined(SWIFT_RESILIENT_CLASS)
# if __has_attribute(objc_class_stub)
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME) __attribute__((objc_class_stub))
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_class_stub)) SWIFT_CLASS_NAMED(SWIFT_NAME)
# else
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME)
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) SWIFT_CLASS_NAMED(SWIFT_NAME)
# endif
#endif
#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif
#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER 
# endif
#endif
#if !defined(SWIFT_ENUM_ATTR)
# if __has_attribute(enum_extensibility)
#  define SWIFT_ENUM_ATTR(_extensibility) __attribute__((enum_extensibility(_extensibility)))
# else
#  define SWIFT_ENUM_ATTR(_extensibility) 
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name, _extensibility) enum _name : _type _name; enum SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# if __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) SWIFT_ENUM(_type, _name, _extensibility)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_WEAK_IMPORT)
# define SWIFT_WEAK_IMPORT __attribute__((weak_import))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if !defined(SWIFT_DEPRECATED_OBJC)
# if __has_feature(attribute_diagnose_if_objc)
#  define SWIFT_DEPRECATED_OBJC(Msg) __attribute__((diagnose_if(1, Msg, "warning")))
# else
#  define SWIFT_DEPRECATED_OBJC(Msg) SWIFT_DEPRECATED_MSG(Msg)
# endif
#endif
#if defined(__OBJC__)
#if !defined(IBSegueAction)
# define IBSegueAction 
#endif
#endif
#if !defined(SWIFT_EXTERN)
# if defined(__cplusplus)
#  define SWIFT_EXTERN extern "C"
# else
#  define SWIFT_EXTERN extern
# endif
#endif
#if !defined(SWIFT_CALL)
# define SWIFT_CALL __attribute__((swiftcall))
#endif
#if !defined(SWIFT_INDIRECT_RESULT)
# define SWIFT_INDIRECT_RESULT __attribute__((swift_indirect_result))
#endif
#if !defined(SWIFT_CONTEXT)
# define SWIFT_CONTEXT __attribute__((swift_context))
#endif
#if !defined(SWIFT_ERROR_RESULT)
# define SWIFT_ERROR_RESULT __attribute__((swift_error_result))
#endif
#if defined(__cplusplus)
# define SWIFT_NOEXCEPT noexcept
#else
# define SWIFT_NOEXCEPT 
#endif
#if !defined(SWIFT_C_INLINE_THUNK)
# if __has_attribute(always_inline)
# if __has_attribute(nodebug)
#  define SWIFT_C_INLINE_THUNK inline __attribute__((always_inline)) __attribute__((nodebug))
# else
#  define SWIFT_C_INLINE_THUNK inline __attribute__((always_inline))
# endif
# else
#  define SWIFT_C_INLINE_THUNK inline
# endif
#endif
#if defined(_WIN32)
#if !defined(SWIFT_IMPORT_STDLIB_SYMBOL)
# define SWIFT_IMPORT_STDLIB_SYMBOL __declspec(dllimport)
#endif
#else
#if !defined(SWIFT_IMPORT_STDLIB_SYMBOL)
# define SWIFT_IMPORT_STDLIB_SYMBOL 
#endif
#endif
#if defined(__OBJC__)
#if __has_feature(objc_modules)
#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif
@import CoreBluetooth;
@import Foundation;
@import ObjectiveC;
#endif

#endif
#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
#if __has_warning("-Wpragma-clang-attribute")
# pragma clang diagnostic ignored "-Wpragma-clang-attribute"
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wnullability"
#pragma clang diagnostic ignored "-Wdollar-in-identifier-extension"

#if __has_attribute(external_source_symbol)
# pragma push_macro("any")
# undef any
# pragma clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in="kairosBTSDK",generated_declaration))), apply_to=any(function,enum,objc_interface,objc_category,objc_protocol))
# pragma pop_macro("any")
#endif

#if defined(__OBJC__)




@class NSString;
enum biostrapDiscoveryType : NSInteger;

SWIFT_CLASS("_TtC11kairosBTSDK6Device")
@interface Device : NSObject
@property (nonatomic, copy) NSString * _Nonnull name;
@property (nonatomic, copy) NSString * _Nonnull id;
@property (nonatomic) enum biostrapDiscoveryType discovery_type;
@property (nonatomic) BOOL batteryValid;
@property (nonatomic) NSInteger batteryLevel;
@property (nonatomic, copy) NSString * _Nonnull wornStatus;
@property (nonatomic, copy) NSString * _Nonnull chargingStatus;
@property (nonatomic, readonly, copy) NSString * _Nonnull modelNumber;
@property (nonatomic, readonly, copy) NSString * _Nonnull firmwareRevision;
@property (nonatomic, readonly, copy) NSString * _Nonnull hardwareRevision;
@property (nonatomic, readonly, copy) NSString * _Nonnull manufacturerName;
@property (nonatomic, readonly, copy) NSString * _Nonnull serialNumber;
@property (nonatomic, readonly, copy) NSString * _Nonnull bluetoothSoftwareRevision;
@property (nonatomic, readonly, copy) NSString * _Nonnull algorithmsSoftwareRevision;
@property (nonatomic, readonly, copy) NSString * _Nonnull sleepSoftwareRevision;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end

typedef SWIFT_ENUM(uint8_t, algorithmPacketType, open) {
  algorithmPacketTypePhilipsSleep = 0x2f,
  algorithmPacketTypeUnknown = 0xff,
};


SWIFT_CLASS("_TtC11kairosBTSDK18biostrapDataPacket")
@interface biostrapDataPacket : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end

enum nextPacketStatusType : uint8_t;
enum hrZoneRangeType : uint8_t;
@class ppgAlgorithmConfiguration;
enum eventType : uint8_t;
enum buttonTapType : uint8_t;
enum buttonCommandType : uint8_t;
enum sessionParameterType : uint8_t;
enum kairosManufacturingTestType : uint8_t;
@class NSURL;

SWIFT_CLASS("_TtC11kairosBTSDK17biostrapDeviceSDK")
@interface biostrapDeviceSDK : NSObject
@property (nonatomic, copy) void (^ _Nullable logV)(NSString * _Nullable, NSString * _Nonnull, NSString * _Nonnull, NSInteger);
@property (nonatomic, copy) void (^ _Nullable logD)(NSString * _Nullable, NSString * _Nonnull, NSString * _Nonnull, NSInteger);
@property (nonatomic, copy) void (^ _Nullable logI)(NSString * _Nullable, NSString * _Nonnull, NSString * _Nonnull, NSInteger);
@property (nonatomic, copy) void (^ _Nullable logW)(NSString * _Nullable, NSString * _Nonnull, NSString * _Nonnull, NSInteger);
@property (nonatomic, copy) void (^ _Nullable logE)(NSString * _Nullable, NSString * _Nonnull, NSString * _Nonnull, NSInteger);
@property (nonatomic, copy) void (^ _Nullable bluetoothReady)(BOOL);
@property (nonatomic, copy) void (^ _Nullable discovered)(NSString * _Nonnull, Device * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable discoveredUnnamed)(NSString * _Nonnull, Device * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable connected)(NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable disconnected)(NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable writeEpochComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable readEpochComplete)(NSString * _Nonnull, BOOL, NSInteger);
@property (nonatomic, copy) void (^ _Nullable endSleepComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable getAllPacketsComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable getAllPacketsAcknowledgeComplete)(NSString * _Nonnull, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable getNextPacketComplete)(NSString * _Nonnull, BOOL, enum nextPacketStatusType, BOOL, NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable getPacketCountComplete)(NSString * _Nonnull, BOOL, NSInteger);
@property (nonatomic, copy) void (^ _Nullable startManualComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable stopManualComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable ledComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable enterShipModeComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable writeSerialNumberComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable readSerialNumberComplete)(NSString * _Nonnull, BOOL, NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable deleteSerialNumberComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable writeAdvIntervalComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable readAdvIntervalComplete)(NSString * _Nonnull, BOOL, NSInteger);
@property (nonatomic, copy) void (^ _Nullable deleteAdvIntervalComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable clearChargeCyclesComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable readChargeCyclesComplete)(NSString * _Nonnull, BOOL, float);
@property (nonatomic, copy) void (^ _Nullable readCanLogDiagnosticsComplete)(NSString * _Nonnull, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable updateCanLogDiagnosticsComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable allowPPGComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable wornCheckComplete)(NSString * _Nonnull, BOOL, NSString * _Nonnull, NSInteger);
@property (nonatomic, copy) void (^ _Nullable rawLoggingComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable resetComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable ppgMetrics)(NSString * _Nonnull, BOOL, NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable ppgFailed)(NSString * _Nonnull, NSInteger);
@property (nonatomic, copy) void (^ _Nullable disableWornDetectComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable enableWornDetectComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable dataPackets)(NSString * _Nonnull, NSInteger, NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable dataComplete)(NSString * _Nonnull, NSInteger, NSInteger, NSInteger, NSInteger, BOOL);
@property (nonatomic, copy) void (^ _Nullable dataFailure)(NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable streamingPacket)(NSString * _Nonnull, NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable dataAvailable)(NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable deviceWornStatus)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable updateFirmwareStarted)(NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable updateFirmwareFinished)(NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable updateFirmwareFailed)(NSString * _Nonnull, NSInteger, NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable updateFirmwareProgress)(NSString * _Nonnull, float);
@property (nonatomic, copy) void (^ _Nullable manufacturingTestComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable manufacturingTestResult)(NSString * _Nonnull, BOOL, NSString * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable endSleepStatus)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable buttonClicked)(NSString * _Nonnull, NSInteger);
@property (nonatomic, copy) void (^ _Nullable setAskForButtonResponseComplete)(NSString * _Nonnull, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable getAskForButtonResponseComplete)(NSString * _Nonnull, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable setHRZoneColorComplete)(NSString * _Nonnull, BOOL, enum hrZoneRangeType);
@property (nonatomic, copy) void (^ _Nullable getHRZoneColorComplete)(NSString * _Nonnull, BOOL, enum hrZoneRangeType, BOOL, BOOL, BOOL, NSInteger, NSInteger);
@property (nonatomic, copy) void (^ _Nullable setHRZoneRangeComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable getHRZoneRangeComplete)(NSString * _Nonnull, BOOL, BOOL, NSInteger, NSInteger);
@property (nonatomic, copy) void (^ _Nullable getPPGAlgorithmComplete)(NSString * _Nonnull, BOOL, ppgAlgorithmConfiguration * _Nonnull, enum eventType);
@property (nonatomic, copy) void (^ _Nullable setAdvertiseAsHRMComplete)(NSString * _Nonnull, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable getAdvertiseAsHRMComplete)(NSString * _Nonnull, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable setButtonCommandComplete)(NSString * _Nonnull, BOOL, enum buttonTapType, enum buttonCommandType);
@property (nonatomic, copy) void (^ _Nullable getButtonCommandComplete)(NSString * _Nonnull, BOOL, enum buttonTapType, enum buttonCommandType);
@property (nonatomic, copy) void (^ _Nullable getPairedComplete)(NSString * _Nonnull, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable setPairedComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable setUnpairedComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable getPageThresholdComplete)(NSString * _Nonnull, BOOL, NSInteger);
@property (nonatomic, copy) void (^ _Nullable setPageThresholdComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable deletePageThresholdComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable recalibratePPGComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable getRawLoggingStatusComplete)(NSString * _Nonnull, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable getWornOverrideStatusComplete)(NSString * _Nonnull, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable deviceChargingStatus)(NSString * _Nonnull, BOOL, BOOL, BOOL);
@property (nonatomic, copy) void (^ _Nullable setSessionParamComplete)(NSString * _Nonnull, BOOL, enum sessionParameterType);
@property (nonatomic, copy) void (^ _Nullable getSessionParamComplete)(NSString * _Nonnull, BOOL, enum sessionParameterType, NSInteger);
@property (nonatomic, copy) void (^ _Nullable resetSessionParamsComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable acceptSessionParamsComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, copy) void (^ _Nullable batteryLevel)(NSString * _Nonnull, NSInteger);
@property (nonatomic, copy) void (^ _Nullable heartRate)(NSString * _Nonnull, NSInteger, NSInteger, NSArray<NSNumber *> * _Nonnull);
@property (nonatomic, copy) void (^ _Nullable airplaneModeComplete)(NSString * _Nonnull, BOOL);
@property (nonatomic, readonly, copy) NSArray<Device *> * _Nonnull connectedDevices;
@property (nonatomic, readonly, copy) NSArray<Device *> * _Nonnull discoveredDevices;
@property (nonatomic, readonly, copy) NSString * _Nonnull version;
- (void)addPairedDeviceWithId:(NSString * _Nonnull)id name:(NSString * _Nonnull)name;
- (void)removePairedDeviceWithId:(NSString * _Nonnull)id;
- (void)clearPairedDevices;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
- (BOOL)startScanInBackground:(BOOL)inBackground forPaired:(BOOL)forPaired forUnpaired:(BOOL)forUnpaired forLegacy:(BOOL)forLegacy SWIFT_WARN_UNUSED_RESULT;
- (void)stopScan;
- (void)connect:(NSString * _Nonnull)id;
- (void)disconnect:(NSString * _Nonnull)id;
- (NSString * _Nonnull)getCSVFromDataPackets:(NSString * _Nonnull)json SWIFT_WARN_UNUSED_RESULT;
- (void)writeEpoch:(NSString * _Nonnull)id newEpoch:(NSInteger)newEpoch;
- (void)readEpoch:(NSString * _Nonnull)id;
- (void)endSleep:(NSString * _Nonnull)id;
- (void)getAllPackets:(NSString * _Nonnull)id pages:(NSInteger)pages delay:(NSInteger)delay;
- (void)getAllPacketsAcknowledge:(NSString * _Nonnull)id ack:(BOOL)ack;
- (void)getNextPacket:(NSString * _Nonnull)id single:(BOOL)single;
- (void)getPacketCount:(NSString * _Nonnull)id;
- (void)disableWornDetect:(NSString * _Nonnull)id;
- (void)enableWornDetect:(NSString * _Nonnull)id;
- (void)startManual:(NSString * _Nonnull)id algorithms:(ppgAlgorithmConfiguration * _Nonnull)algorithms;
- (void)stopManual:(NSString * _Nonnull)id;
- (void)led:(NSString * _Nonnull)id red:(BOOL)red green:(BOOL)green blue:(BOOL)blue blink:(BOOL)blink seconds:(NSInteger)seconds;
- (void)enterShipMode:(NSString * _Nonnull)id;
- (void)writeSerialNumber:(NSString * _Nonnull)id partID:(NSString * _Nonnull)partID;
- (void)readSerialNumber:(NSString * _Nonnull)id;
- (void)deleteSerialNumber:(NSString * _Nonnull)id;
- (void)writeAdvInterval:(NSString * _Nonnull)id seconds:(NSInteger)seconds;
- (void)readAdvInterval:(NSString * _Nonnull)id;
- (void)deleteAdvInterval:(NSString * _Nonnull)id;
- (void)clearChargeCycles:(NSString * _Nonnull)id;
- (void)readChargeCycles:(NSString * _Nonnull)id;
- (void)readCanLogDiagnostics:(NSString * _Nonnull)id;
- (void)updateCanLogDiagnostics:(NSString * _Nonnull)id allow:(BOOL)allow;
- (void)manufacturingTest:(NSString * _Nonnull)id test:(enum kairosManufacturingTestType)test;
- (void)setAskForButtonResponse:(NSString * _Nonnull)id enable:(BOOL)enable;
- (void)getAskForButtonResponse:(NSString * _Nonnull)id;
- (void)setHRZoneColor:(NSString * _Nonnull)id type:(enum hrZoneRangeType)type red:(BOOL)red green:(BOOL)green blue:(BOOL)blue on_milliseconds:(NSInteger)on_milliseconds off_milliseconds:(NSInteger)off_milliseconds;
- (void)getHRZoneColor:(NSString * _Nonnull)id type:(enum hrZoneRangeType)type;
- (void)setHRZoneRange:(NSString * _Nonnull)id enabled:(BOOL)enabled high_value:(NSInteger)high_value low_value:(NSInteger)low_value;
- (void)getHRZoneRange:(NSString * _Nonnull)id;
- (void)getPPGAlgorithm:(NSString * _Nonnull)id;
- (void)setAdvertiseAsHRM:(NSString * _Nonnull)id asHRM:(BOOL)asHRM;
- (void)getAdvertiseAsHRM:(NSString * _Nonnull)id;
- (void)setButtonCommand:(NSString * _Nonnull)id tap:(enum buttonTapType)tap command:(enum buttonCommandType)command;
- (void)getButtonCommand:(NSString * _Nonnull)id tap:(enum buttonTapType)tap;
- (void)setPaired:(NSString * _Nonnull)id;
- (void)setUnpaired:(NSString * _Nonnull)id;
- (void)getPaired:(NSString * _Nonnull)id;
- (void)setPageThreshold:(NSString * _Nonnull)id threshold:(NSInteger)threshold;
- (void)getPageThreshold:(NSString * _Nonnull)id;
- (void)deletePageThreshold:(NSString * _Nonnull)id;
- (void)recalibratePPG:(NSString * _Nonnull)id;
- (void)allowPPG:(NSString * _Nonnull)id allow:(BOOL)allow;
- (void)wornCheck:(NSString * _Nonnull)id;
- (void)rawLogging:(NSString * _Nonnull)id enable:(BOOL)enable;
- (void)getRawLoggingStatus:(NSString * _Nonnull)id;
- (void)getWornOverrideStatus:(NSString * _Nonnull)id;
- (void)airplaneMode:(NSString * _Nonnull)id;
- (void)reset:(NSString * _Nonnull)id;
- (void)updateFirmware:(NSString * _Nonnull)id file:(NSURL * _Nonnull)file;
- (void)cancelFirmwareUpdate:(NSString * _Nonnull)id;
- (void)setSessionParam:(NSString * _Nonnull)id parameter:(enum sessionParameterType)parameter value:(NSInteger)value;
- (void)getSessionParam:(NSString * _Nonnull)id parameter:(enum sessionParameterType)parameter;
- (void)resetSessionParams:(NSString * _Nonnull)id;
- (void)acceptSessionParams:(NSString * _Nonnull)id;
@end

typedef SWIFT_ENUM(NSInteger, biostrapDiscoveryType, open) {
  biostrapDiscoveryTypeLegacy = 1,
  biostrapDiscoveryTypeUnpaired = 2,
  biostrapDiscoveryTypeUnpaired_w_uuid = 3,
  biostrapDiscoveryTypePaired = 4,
  biostrapDiscoveryTypePaired_w_uuid = 5,
  biostrapDiscoveryTypeUnknown = 99,
};


@class CBCentralManager;
@class CBPeripheral;
@class NSNumber;

@interface biostrapDeviceSDK (SWIFT_EXTENSION(kairosBTSDK)) <CBCentralManagerDelegate>
- (void)centralManagerDidUpdateState:(CBCentralManager * _Nonnull)central;
- (void)centralManager:(CBCentralManager * _Nonnull)central didDiscoverPeripheral:(CBPeripheral * _Nonnull)peripheral advertisementData:(NSDictionary<NSString *, id> * _Nonnull)advertisementData RSSI:(NSNumber * _Nonnull)RSSI;
- (void)centralManager:(CBCentralManager * _Nonnull)central didConnectPeripheral:(CBPeripheral * _Nonnull)peripheral;
- (void)centralManager:(CBCentralManager * _Nonnull)central didDisconnectPeripheral:(CBPeripheral * _Nonnull)peripheral error:(NSError * _Nullable)error;
- (void)centralManager:(CBCentralManager * _Nonnull)central didFailToConnectPeripheral:(CBPeripheral * _Nonnull)peripheral error:(NSError * _Nullable)error;
- (void)centralManager:(CBCentralManager * _Nonnull)central willRestoreState:(NSDictionary<NSString *, id> * _Nonnull)dict;
@end

@class CBService;
@class CBL2CAPChannel;
@class CBDescriptor;
@class CBCharacteristic;

@interface biostrapDeviceSDK (SWIFT_EXTENSION(kairosBTSDK)) <CBPeripheralDelegate>
- (void)peripheralDidUpdateName:(CBPeripheral * _Nonnull)peripheral;
- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral * _Nonnull)peripheral;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didModifyServices:(NSArray<CBService *> * _Nonnull)invalidatedServices;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didReadRSSI:(NSNumber * _Nonnull)RSSI error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didOpenL2CAPChannel:(CBL2CAPChannel * _Nullable)channel error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForDescriptor:(CBDescriptor * _Nonnull)descriptor error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForDescriptor:(CBDescriptor * _Nonnull)descriptor error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverIncludedServicesForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)centralManager:(CBCentralManager * _Nonnull)central didUpdateANCSAuthorizationForPeripheral:(CBPeripheral * _Nonnull)peripheral;
@end


SWIFT_CLASS("_TtC11kairosBTSDK23biostrapStreamingPacket")
@interface biostrapStreamingPacket : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end

typedef SWIFT_ENUM(uint8_t, bookendType, open) {
  bookendTypeActivity = 0x00,
  bookendTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, buttonCommandType, open) {
  buttonCommandTypeNone = 0x00,
  buttonCommandTypeShowBattery = 0x01,
  buttonCommandTypeAdvertiseShowConnection = 0x02,
  buttonCommandTypeHrmAdvertiseToggleActivity = 0x03,
  buttonCommandTypeShutDown = 0x04,
  buttonCommandTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, buttonTapType, open) {
  buttonTapTypeSingle = 0x00,
  buttonTapTypeDouble = 0x01,
  buttonTapTypeTriple = 0x02,
  buttonTapTypeLong = 0x03,
  buttonTapTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, debugDevice, open) {
  debugDeviceSpectralParameters = 0x00,
  debugDeviceUnknownDevice = 0xff,
};

typedef SWIFT_ENUM(uint8_t, deviceParameterType, open) {
  deviceParameterTypeSerialNumber = 0x01,
  deviceParameterTypeChargeCycle = 0x02,
  deviceParameterTypeAdvertisingInterval = 0x03,
  deviceParameterTypeCanLogDiagnostics = 0x04,
  deviceParameterTypePaired = 0x07,
  deviceParameterTypePageThreshold = 0x08,
};

typedef SWIFT_ENUM(uint8_t, diagnosticType, open) {
  diagnosticTypeSleep = 0x00,
  diagnosticTypePpgBroken = 0x01,
  diagnosticTypePmicStatus = 0x02,
  diagnosticTypeAlgorithm = 0x03,
  diagnosticTypeRotation = 0x04,
  diagnosticTypePmicWatchdog = 0x05,
  diagnosticTypeBluetoothPacket = 0xfe,
  diagnosticTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, eventType, open) {
  eventTypePpgUserTriggerButton = 0x00,
  eventTypePpgUserTriggerAutoActivity = 0x01,
  eventTypePpgUserTriggerBLE = 0x02,
  eventTypePpgUserTriggerUART = 0x03,
  eventTypePpgUserTriggerButtonStop = 0x04,
  eventTypePpgUserTriggerAutoActivityStop = 0x05,
  eventTypePpgUserTriggerBLEStop = 0x06,
  eventTypePpgUserTriggerUARTStop = 0x07,
  eventTypePpgUserTriggerManufacturingTestStop = 0x08,
  eventTypeSinglePress = 0x09,
  eventTypeDoublePress = 0x0a,
  eventTypeTriplePress = 0x0b,
  eventTypeLongPress = 0x0c,
  eventTypeNone = 0x0d,
  eventTypePpgWornStop = 0x0e,
  eventTypePpgTimerStop = 0x0f,
  eventTypePpgFWStop = 0x10,
  eventTypePpgFWStart = 0x11,
  eventTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, extendedFirmwareError, open) {
  extendedFirmwareErrorNO_ERROR = 0x00,
  extendedFirmwareErrorINVALID_ERROR_CODE = 0x01,
  extendedFirmwareErrorWRONG_COMMAND_FORMAT = 0x02,
  extendedFirmwareErrorUNKNOWN_COMMAND = 0x03,
  extendedFirmwareErrorINIT_COMMAND_INVALID = 0x04,
  extendedFirmwareErrorFW_VERSION_FAILURE = 0x05,
  extendedFirmwareErrorHW_VERSION_FAILURE = 0x06,
  extendedFirmwareErrorSD_VERSION_FAILURE = 0x07,
  extendedFirmwareErrorSIGNATURE_MISSING = 0x08,
  extendedFirmwareErrorWRONG_HASH_TYPE = 0x09,
  extendedFirmwareErrorHASH_FAILED = 0x0A,
  extendedFirmwareErrorWRONG_SIGNATURE_TYPE = 0x0B,
  extendedFirmwareErrorVERIFICATION_FAILED = 0x0C,
  extendedFirmwareErrorINSUFFICIENT_SPACE = 0x0D,
};

typedef SWIFT_ENUM(uint8_t, firmwareErorCode, open) {
  firmwareErorCodeInvalid = 0x00,
  firmwareErorCodeSuccess = 0x01,
  firmwareErorCodeOpcodeNotSupported = 0x02,
  firmwareErorCodeInvalidParameters = 0x03,
  firmwareErorCodeInsufficientResources = 0x04,
  firmwareErorCodeInvalidObject = 0x05,
  firmwareErorCodeUnsupportedType = 0x07,
  firmwareErorCodeOperationNotPermitted = 0x08,
  firmwareErorCodeOperationFailed = 0x0A,
  firmwareErorCodeExtendedError = 0x0B,
};

typedef SWIFT_ENUM(uint8_t, hrZoneRangeType, open) {
  hrZoneRangeTypeBelow = 0x00,
  hrZoneRangeTypeWithin = 0x01,
  hrZoneRangeTypeAbove = 0x02,
  hrZoneRangeTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, kairosManufacturingTestType, open) {
  kairosManufacturingTestTypeFlashIF = 0x01,
  kairosManufacturingTestTypeFlashArray = 0x02,
  kairosManufacturingTestTypeSpectralIF = 0x03,
  kairosManufacturingTestTypeSpectralFIFO = 0x04,
  kairosManufacturingTestTypeImuIF = 0x05,
  kairosManufacturingTestTypeImuFIFO = 0x06,
  kairosManufacturingTestTypeLed = 0x07,
  kairosManufacturingTestTypePpgUserTriggerButton = 0x09,
  kairosManufacturingTestTypeSpectralLEDS = 0x0A,
  kairosManufacturingTestTypeImuSelfTest = 0x0B,
  kairosManufacturingTestTypeSpectralLEDLeakage = 0x0C,
  kairosManufacturingTestTypeImuNoiseFloor = 0x0D,
  kairosManufacturingTestTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, nextPacketStatusType, open) {
  nextPacketStatusTypeSuccessful = 0x00,
  nextPacketStatusTypeBusy = 0x01,
  nextPacketStatusTypeCaughtUp = 0x02,
  nextPacketStatusTypePageEmpty = 0x03,
  nextPacketStatusTypeUnknownPacket = 0x04,
  nextPacketStatusTypeBadCommandFormat = 0x05,
  nextPacketStatusTypeBadJSON = 0xfc,
  nextPacketStatusTypeBadSDKDecode = 0xfd,
  nextPacketStatusTypeMissingDevice = 0xfe,
  nextPacketStatusTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, packetType, open) {
  packetTypeUnknown = 0x00,
  packetTypeSteps = 0x81,
  packetTypeActivity = 0x83,
  packetTypeTemp = 0x84,
  packetTypeWorn = 0x85,
  packetTypeSleep = 0x86,
  packetTypeDiagnostic = 0x87,
  packetTypePpg_failed = 0x88,
  packetTypeBattery = 0x89,
  packetTypeCharger = 0x8a,
  packetTypePpg_metrics = 0x8b,
  packetTypeContinuous_hr = 0x8c,
  packetTypeSteps_active = 0x8d,
  packetTypeBbi = 0x8e,
  packetTypeCadence = 0x8f,
  packetTypeEvent = 0x90,
  packetTypeBookend = 0x91,
  packetTypeAlgorithmData = 0x92,
  packetTypeRawAccelXADC = 0xc0,
  packetTypeRawAccelYADC = 0xc1,
  packetTypeRawAccelZADC = 0xc2,
  packetTypeRawAccelCompressedXADC = 0xc3,
  packetTypeRawAccelCompressedYADC = 0xc4,
  packetTypeRawAccelCompressedZADC = 0xc5,
  packetTypeRawGyroXADC = 0xc8,
  packetTypeRawGyroYADC = 0xc9,
  packetTypeRawGyroZADC = 0xca,
  packetTypeRawGyroCompressedXADC = 0xcb,
  packetTypeRawGyroCompressedYADC = 0xcc,
  packetTypeRawGyroCompressedZADC = 0xcd,
  packetTypePpgCalibrationStart = 0xe0,
  packetTypePpgCalibrationDone = 0xd0,
  packetTypeMotionLevel = 0xd1,
  packetTypeRawPPGCompressedGreen = 0xd3,
  packetTypeRawPPGCompressedRed = 0xd4,
  packetTypeRawPPGCompressedIR = 0xd5,
  packetTypeRawAccelFifoCount = 0xe1,
  packetTypeRawPPGProximity = 0xe2,
  packetTypeRawPPGGreen = 0xe3,
  packetTypeRawPPGRed = 0xe4,
  packetTypeRawPPGIR = 0xe5,
  packetTypeRawPPGFifoCount = 0xe6,
  packetTypeMilestone = 0xf0,
  packetTypeSettings = 0xf1,
  packetTypeCaughtUp = 0xfe,
};


SWIFT_CLASS("_TtC11kairosBTSDK25ppgAlgorithmConfiguration")
@interface ppgAlgorithmConfiguration : NSObject
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@property (nonatomic, readonly, copy) NSString * _Nonnull commandString;
@end

typedef SWIFT_ENUM(uint8_t, ppgFailedType, open) {
  ppgFailedTypeWorn = 0x00,
  ppgFailedTypeStart = 0x01,
  ppgFailedTypeInterrupt = 0x02,
  ppgFailedTypeOverflow = 0x03,
  ppgFailedTypeFifoRead = 0x04,
  ppgFailedTypeAlreadyRunning = 0x05,
  ppgFailedTypeLowBattery = 0x06,
  ppgFailedTypeUserDisallowed = 0x07,
  ppgFailedTypeTimedNotWorn = 0x08,
  ppgFailedTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, ppgStatusType, open) {
  ppgStatusTypeUserContinuous = 0x00,
  ppgStatusTypeUserComplete = 0x01,
  ppgStatusTypeBackgroundComplete = 0x02,
  ppgStatusTypeBackgroundMedtor = 0x03,
  ppgStatusTypeBackgroundWornStop = 0x04,
  ppgStatusTypeBackgroundUserStop = 0x05,
  ppgStatusTypeBackgroundMotionStop = 0x06,
  ppgStatusTypeUserWornStop = 0x07,
  ppgStatusTypeUserUserStop = 0x08,
  ppgStatusTypeUserMotionStop = 0x09,
  ppgStatusTypeUserMedtorMotion = 0x0a,
  ppgStatusTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, sessionParameterType, open) {
  sessionParameterTypePpgCapturePeriod = 0x00,
  sessionParameterTypePpgCaptureDuration = 0x01,
  sessionParameterTypeTag = 0x10,
  sessionParameterTypeReset = 0xfd,
  sessionParameterTypeAccept = 0xfe,
  sessionParameterTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, settingsType, open) {
  settingsTypeAccelHalfRange = 0x00,
  settingsTypeGyroHalfRange = 0x01,
  settingsTypeImuSamplingRate = 0x02,
  settingsTypePpgCapturePeriod = 0x03,
  settingsTypePpgCaptureDuration = 0x04,
  settingsTypePpgSamplingRate = 0x05,
  settingsTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, streamingType, open) {
  streamingTypeHr = 0x00,
  streamingTypeHrv = 0x01,
  streamingTypeRr = 0x02,
  streamingTypeBbi = 0x03,
  streamingTypePpgSNR = 0x04,
  streamingTypePpgWave = 0x05,
  streamingTypeMotionState = 0x06,
  streamingTypeUnknown = 0xff,
};

typedef SWIFT_ENUM(uint8_t, wavelengthType, open) {
  wavelengthTypeGreen = 0x00,
  wavelengthTypeRed = 0x01,
  wavelengthTypeIR = 0x02,
  wavelengthTypeWhiteIR = 0x03,
  wavelengthTypeWhiteWhite = 0x04,
  wavelengthTypeUnknown = 0xff,
};

#endif
#if __has_attribute(external_source_symbol)
# pragma clang attribute pop
#endif
#if defined(__cplusplus)
#endif
#pragma clang diagnostic pop
#endif

#else
#error unsupported Swift architecture
#endif
