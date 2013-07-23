library test.generate;

import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:bot_io/bot_io.dart';
import "package:discovery_api_client_generator/generator.dart";

const _testLibName = 'discovery';
const _testLibVer = 'v1';

void main() {
  group('generate', () {
    test('no args', () {
      return _runGenerate([])
          .then((ProcessResult pr) {
            expect(pr.exitCode, 1);
            expect(pr.stdout, startsWith('Missing arguments'));
            expect(pr, _hasUsageInStdOut);
          });
    });

    test('help', () {
      return _runGenerate(['--help'])
          .then((ProcessResult pr) {
            expect(pr.exitCode, 0);
            expect(pr, _hasUsageInStdOut);
          });
    });

    test('validate library', _testSingleLibraryGeneration);

    test('validate generate via cli', _testSingleLibraryGenerationViaCLI);

    test('"rest" args should throw', () {
      TempDir tmpDir;

      return TempDir.create()
          .then((value) {
            tmpDir = value;

            return _runGenerate(['--api', _testLibName, '-v', _testLibVer, '-o', tmpDir.path, 'silly_extra_arg']);
          })
          .then((ProcessResult pr) {
            expect(pr.exitCode, 1);
            expect(pr, _hasUsageInStdOut);
          })
          .whenComplete(() {
            if(tmpDir != null) {
              return tmpDir.dispose();
            }
          });
    });

    test('missing output directory should throw', () {
      TempDir tmpDir;

      return TempDir.create()
          .then((value) {
            tmpDir = value;

            return _runGenerate(['--api', _testLibName, '-v', _testLibVer]);
          })
          .then((ProcessResult pr) {
            expect(pr.exitCode, 1);
            expect(pr, _hasUsageInStdOut);
          })
          .whenComplete(() {
            if(tmpDir != null) {
              return tmpDir.dispose();
            }
          });
    });
  });
}

Future _testSingleLibraryGeneration() {
  TempDir tmpDir;

  return TempDir.create()
      .then((value) {
        tmpDir = value;

        return generateLibrary(_testLibName, _testLibVer, tmpDir.path);
      })
      .then((bool success) {
        expect(success, isTrue);

        return _validateDirectory(tmpDir.dir, _testLibName, _testLibVer);
      })
      .whenComplete(() {
        if(tmpDir != null) {
          return tmpDir.dispose();
        }
      });
}

Future _testSingleLibraryGenerationViaCLI() {
  TempDir tmpDir;

  return TempDir.create()
      .then((value) {
        tmpDir = value;

        return _runGenerate(['--api', _testLibName, '-v', _testLibVer, '-o', tmpDir.path]);
      })
      .then((ProcessResult pr) {
        expect(pr.exitCode, 0);

        return _validateDirectory(tmpDir.dir, _testLibName, _testLibVer);
      })
      .whenComplete(() {
        if(tmpDir != null) {
          return tmpDir.dispose();
        }
      });
}

Future _validateDirectory(Directory dir, String libName, String libVer) {
  var expectedMap = _createLibValidate(libName, libVer);

  return IoHelpers.verifyContents(dir, expectedMap)
    .then((bool validates) {
      expect(validates, isTrue, reason: 'Directory structure should be valid');
    });
}

Map _createLibValidate(String libName, String libVersion) {
  final rootDir = 'dart_${libName}_${libVersion}_api_client';

  var expectedMap = {};
  expectedMap[rootDir] = new EntityExistsValidator(FileSystemEntityType.DIRECTORY);

  return expectedMap;
}

final Matcher _hasUsageInStdOut = predicate((ProcessResult pr) => pr.stdout.contains("""Usage:
   generate.dart"""));

Future<ProcessResult> _runGenerate(Iterable<String> args) {

  var theArgs = ['--checked', './bin/generate.dart']
    ..addAll(args);

  return Process.run('dart', theArgs);
}
