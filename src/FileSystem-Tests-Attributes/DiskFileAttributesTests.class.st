"
Try and test the file attributes primitives.

As Pharo doesn't yet provide a mechanism to set the attributes, pick a few well known files and make sure they have reasonable attributes, e.g. the VM is executable, it isn't older than when the classes were first created or newer than today, etc.

"
Class {
	#name : #DiskFileAttributesTests,
	#superclass : #TestCase,
	#category : #'FileSystem-Tests-Attributes'
}

{ #category : #accessing }
DiskFileAttributesTests class >> resources [

	^Array with: DiskFileAttributesTestsResources.
]

{ #category : #'private-helpers' }
DiskFileAttributesTests >> attributesCollection [
	"Answer an array of FileAttributes for the test resource file.
	This is currently a single entry, but leaving the infrastructure in place in case it is extended."
	
	^{
		self tempFileEntry.
	}
]

{ #category : #'private-helpers' }
DiskFileAttributesTests >> attributesCollectionDo: aBlock [
	"Evaluate the supplied block for each of the attribute cache modes"

	^self attributesCollection do: aBlock
]

{ #category : #'private-helpers' }
DiskFileAttributesTests >> collectionAssert: aBlock [
	"Evaluate the assertion block for each of the FileAttribute cache modes"

	self attributesCollectionDo:
		[ :each | self assert: (aBlock value: each) ].
]

{ #category : #'private-helpers' }
DiskFileAttributesTests >> collectionAssert: aBlock equals: expected [
	"Evaluate the assertion block for each of the FileAttribute cache modes"

	self attributesCollectionDo:
		[ :each | self assert: (aBlock value: each) equals: expected ].
]

{ #category : #'private-helpers' }
DiskFileAttributesTests >> tempFileEntry [

	| file |
	
	file := self tempFileResource file resolve.
	^DiskDirectoryEntry reference: file.
]

{ #category : #'private-helpers' }
DiskFileAttributesTests >> tempFileResource [

	^DiskFileAttributesTestsResources current
]

{ #category : #tests }
DiskFileAttributesTests >> testAccessTime [

	| resource accessTime |
	resource := self tempFileResource.
	self attributesCollectionDo: [ :each |
		accessTime := each accessTime.
		self assert: resource beforeCreationTime <= accessTime.
		self assert: resource afterCreationTime >= accessTime.
		].
]

{ #category : #tests }
DiskFileAttributesTests >> testCreationTime [

	| resource creationTime |
	resource := self tempFileResource.
	self attributesCollectionDo: [ :each |
		creationTime := each creationTime.
		self assert: resource beforeCreationTime <= creationTime.
		self assert: resource afterCreationTime >= creationTime.
		].
]

{ #category : #tests }
DiskFileAttributesTests >> testExists [

	| file |
	file := self tempFileResource file resolve.
	self assert: (DiskDirectoryEntry exists: file path in: file fileSystem)
]

{ #category : #tests }
DiskFileAttributesTests >> testExistsNot [

	| file |
	file := '/thisfileshouldnot.exist' asFileReference.
	self deny: (DiskDirectoryEntry exists: file path in: file fileSystem).

]

{ #category : #tests }
DiskFileAttributesTests >> testFileSize [

	self collectionAssert: [ :each | each size ] equals: 72.
]

{ #category : #tests }
DiskFileAttributesTests >> testFromPlatformPath [

	| testString platformByteArray nativeByteArray |

	testString := '1234žřč'.
	platformByteArray := { 
		#Win32 -> #[49 0 50 0 51 0 52 0 126 1 89 1 13 1].
		#Win64 -> #[49 0 50 0 51 0 52 0 126 1 89 1 13 1].
		#unix -> testString utf8Encoded.
		#'Mac OS' -> #[49 50 51 52 122 204 140 114 204 140 99 204 140].
	 } asDictionary at: OSPlatform current platformName asSymbol.
	nativeByteArray := File fromPlatformPath: platformByteArray.
	self assert: nativeByteArray utf8Decoded equals: testString.
]

{ #category : #tests }
DiskFileAttributesTests >> testIsBlock [

	self collectionAssert: [ :each | each isBlock ] equals: false.
]

{ #category : #tests }
DiskFileAttributesTests >> testIsCharacter [

	self collectionAssert: [ :each | each isCharacter ] equals: false.
]

{ #category : #tests }
DiskFileAttributesTests >> testIsDirectory [

	| file |

	self collectionAssert: [ :each | each isDirectory ] equals: false.
	file := FileLocator temp resolve.
	self assert: (DiskDirectoryEntry reference: file) isDirectory.
]

{ #category : #tests }
DiskFileAttributesTests >> testIsExecutable [

	| file filesystem path |
	file := FileLocator vmBinary resolve.
	filesystem := file fileSystem.
	path := file path.
	self assert: (DiskDirectoryEntry reference: file) isExecutable.

]

{ #category : #tests }
DiskFileAttributesTests >> testIsFIFO [

	self collectionAssert: [ :each | each isFIFO ] equals: false.
]

{ #category : #tests }
DiskFileAttributesTests >> testIsReadable [

	self collectionAssert: [ :each | each isReadable ].
]

{ #category : #tests }
DiskFileAttributesTests >> testIsRegular [

	self collectionAssert: [ :each | each isRegular ]
]

{ #category : #tests }
DiskFileAttributesTests >> testIsSocket [

	self collectionAssert: [ :each | each isSocket ] equals: false.
]

{ #category : #tests }
DiskFileAttributesTests >> testIsSymlink [

	self collectionAssert: [ :each | each isSymlink ] equals: false.
]

{ #category : #tests }
DiskFileAttributesTests >> testIsWriteable [

	self collectionAssert: [ :each | each isWritable ].
]

{ #category : #tests }
DiskFileAttributesTests >> testModificationTime [

	| resource modificationTime |
	resource := self tempFileResource.
	self attributesCollectionDo: [ :each |
		modificationTime := each modificationTime.
		self assert: resource beforeCreationTime <= modificationTime.
		self assert: resource afterCreationTime >= modificationTime.
		].
]

{ #category : #tests }
DiskFileAttributesTests >> testNLink [
	"Assume that there is only one hard link to the just created temporary file"

	OSPlatform current name = #'Win32' ifTrue: 
		[ self should: [ self tempFileResource file numberOfHardLinks ] raise: FileAttributeNotSupported ]
	ifFalse:
		[ self collectionAssert: [ :each | each numberOfHardLinks ] equals: 1 ].
]

{ #category : #tests }
DiskFileAttributesTests >> testPermissions [

	| fileReference oldPermissions newPermissions |

	fileReference := (FileLocator temp / ('FileAttributesTests-', UUIDGenerator next asString, '.txt')) resolve.

	fileReference createFile.
	[ 
		oldPermissions := self tempFileEntry permissions.
		newPermissions := FileSystemPermission posixPermissions: 8r007.
		"Check that the existing permissions don't happen to match the test permissions"
		self assert: oldPermissions ~= newPermissions.

		"Setting permissions aren't supported on Windows"
		OSPlatform current isWindows ifTrue: [ 
			self should: [ fileReference permissions: newPermissions ] raise: Error ]
		ifFalse: [ 
			fileReference permissions: newPermissions.
			self assert: fileReference permissions equals: newPermissions ].
	] ensure: [ fileReference delete ]
]

{ #category : #tests }
DiskFileAttributesTests >> testSymlinkUidGid [

	| fileReference oldUid oldGid |

	fileReference := FileLocator temp / ('FileAttributesTests-', UUIDGenerator next asString, '.txt').
	fileReference createFile.
	[ 
		oldUid := fileReference uid.
		oldGid := fileReference gid.

		"Setting ownership isn't supported on Windows"
		OSPlatform current isWindows ifTrue: [ 
			self should: [ fileReference symlinkUid: nil gid: nil ] raise: Error ]
		ifFalse: [ 
			"Since we can't reliably determine new test ids, call the method without changing values.
			This will at least test that the primitive can be called and doesn't do something unexpected."
			fileReference symlinkUid: nil gid: nil.
			self assert: fileReference uid equals: oldUid.
			self assert: fileReference gid equals: oldGid ].
	] ensure: [ fileReference delete ]
]

{ #category : #tests }
DiskFileAttributesTests >> testTargetFile [

	"The temporary file isn't a symbolic link, so the targetFile is not supported"
	self attributesCollectionDo: [ :each |
		self should: [ each targetFileReference ] raise: FileAttributeNotSupported ].

]

{ #category : #tests }
DiskFileAttributesTests >> testToPlatformPath [

	| testString platformByteArray expectedByteArray |

	testString := '1234žřč'.
	platformByteArray := File toPlatformPath: testString.
	expectedByteArray := { 
		#Win32 -> #[49 0 50 0 51 0 52 0 126 1 89 1 13 1].
		#Win64 -> #[49 0 50 0 51 0 52 0 126 1 89 1 13 1].
		#unix -> testString utf8Encoded.
		#'Mac OS' -> #[49 50 51 52 122 204 140 114 204 140 99 204 140].
	 } asDictionary at: OSPlatform current platformName asSymbol.
	self assert: platformByteArray equals: expectedByteArray.
]

{ #category : #tests }
DiskFileAttributesTests >> testUidGid [

	| fileReference oldUid oldGid |

	fileReference := FileLocator temp / ('FileAttributesTests-', UUIDGenerator next asString, '.txt').
	fileReference createFile.
	[ 
		oldUid := fileReference uid.
		oldGid := fileReference gid.

		"Setting ownership isn't supported on Windows"
		OSPlatform current isWindows ifTrue: [ 
			self should: [ fileReference uid: nil gid: nil ] raise: Error ]
		ifFalse: [ 
			"Since we can't reliably determine new test ids, call the method without changing values.
			This will at least test that the primitive can be called and doesn't do something unexpected."
			fileReference uid: nil gid: nil.
			self assert: fileReference uid equals: oldUid.
			self assert: fileReference gid equals: oldGid ].
	] ensure: [ fileReference delete ]
]
