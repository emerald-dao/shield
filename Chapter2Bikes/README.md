# Contract Review on Chapter2Bikes

This contract review is brought to you by Bam from Emerald City. 
We will go through this contract as an educational resources. 

This contract is not yet deployed to mainnet and it should acts as one of the typical NFT contracts on flow. 
By reviewing this contract, we can have a better idea of what an NFT contract should include. And pin out the things we should red-flag that. 

## Events

Events are ways to communicate with the offchain world. It should be fine as it is just to keep things in order and trackable. 

```cadence
  pub event ContractInitialized()  // declared but never emitted 
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event Minted(id: UInt64)
  pub event NFTDestroyed(id: UInt64)  // declared but never emitted 

  // Named Paths
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  // Better add a CollectionProviderPath if the NFT is intended to be traded on Marketplaces. 
  pub let AdminStoragePath: StoragePath
  pub let AdminPrivatePath: PrivatePath // There should be no resource that take the capability of admin. It should be fine without the adminPrivatePath

```

## Variables 

Variables are storage in contracts. 
It should be fine as long as the variables are not set as `pub(set)` (which means everyone have access to this can change that.)

```cadence
  // Contract Level Fields
  pub var totalSupply: UInt64
  pub var frameEditionSupply: UInt64
  pub var paintingEditionSupply: UInt64
```

## Edition

Editions should be exposed to MetadataViews. 
And the Enum is not implemented to NFT resource itself 

### Original Contract 

```cadence 
  // Each NFT is associated to an Edition/Type: Frame or Painting.
  pub enum Edition: UInt8 {
    pub case frame
    pub case painting
  }
``` 

NFT resource 

```cadence 
// Resource that represents the a Chapter2Bikes NFT
  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    pub let id: UInt64

    pub let edition: UInt8

    pub var metadata: {String: String}

    init(_edition: UInt8, _metadata: {String: String}) {
      self.id = Chapter2Bikes.totalSupply
      self.edition = _edition
      self.metadata = _metadata

      // Total Supply
      Chapter2Bikes.totalSupply = Chapter2Bikes.totalSupply + 1

      // Edition Supply
      if (_edition == 0) {
        Chapter2Bikes.frameEditionSupply = Chapter2Bikes.frameEditionSupply + 1
      } else if (_edition == 1) {
        Chapter2Bikes.paintingEditionSupply = Chapter2Bikes.paintingEditionSupply + 1
      } else {
        // Invalid Edition
        panic("Edition is invalid. Options: 0(Frame) or 1(Painting)")
      }

      // Emit Minted Event
      emit Minted(id: self.id)
    }

    pub fun getViews(): [Type] {
      return [
          Type<MetadataViews.Display>(),
          Type<MetadataViews.Editions>(),
          Type<MetadataViews.ExternalURL>(),
          Type<MetadataViews.NFTCollectionData>(),
          Type<MetadataViews.NFTCollectionDisplay>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
          case Type<MetadataViews.Display>():
            return MetadataViews.Display(
                name: self.metadata["name"]!,
                description: self.metadata["description"]!,
                thumbnail: MetadataViews.HTTPFile(url: self.metadata["external_url"]!)
            )
          case Type<MetadataViews.Editions>():
            // 50 Frame editions and 20 Painting editions
            let frameEditionInfo = MetadataViews.Edition(name: "Chapter2Bikes Frame Edition", number: self.id, max: 50)
            let paintingEditionInfo = MetadataViews.Edition(name: "Chapter2Bikes Painting Edition", number: self.id, max: 20)
            let editionList: [MetadataViews.Edition] = [frameEditionInfo, paintingEditionInfo]
            return MetadataViews.Editions(editionList)
          case Type<MetadataViews.ExternalURL>():
            return MetadataViews.ExternalURL("https://ethos.mypinata.cloud/ipfs/{ipfs hash}/{collection id}-50-00.png")
          case Type<MetadataViews.NFTCollectionData>():
            return MetadataViews.NFTCollectionData(
                storagePath: Chapter2Bikes.CollectionStoragePath,
                publicPath: Chapter2Bikes.CollectionPublicPath,
                providerPath: /private/Chapter2BikesCollection,
                publicCollection: Type<&Chapter2Bikes.Collection{Chapter2Bikes.CollectionPublic}>(),
                publicLinkedType: Type<&Chapter2Bikes.Collection{Chapter2Bikes.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                providerLinkedType: Type<&Chapter2Bikes.Collection{Chapter2Bikes.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                  return <- Chapter2Bikes.createEmptyCollection()
                })
            )
          case Type<MetadataViews.NFTCollectionDisplay>():
            let frameMedia = MetadataViews.Media(
              file: MetadataViews.HTTPFile(url: "https://ethos.mypinata.cloud/ipfs/{ipfs hash}/{collection id}-50-00.png"),
              mediaType: "video/mp4"
            )
            let paintingMedia = MetadataViews.Media(
              file: MetadataViews.HTTPFile(url: "https://ethos.mypinata.cloud/ipfs/{ipfs hash}/{collection id}-20-00.png"),
              mediaType: "image/png"
            )
            return MetadataViews.NFTCollectionDisplay(
              name: "Chapter2Bikes Collection",
              description: "Chapter2Bikes collection description",
              externalURL: MetadataViews.ExternalURL("https://ethos.mypinata.cloud/ipfs/{ipfs hash}/{collection id}-50-00.png"),
              frameImage: frameMedia,
              paintingImage: paintingMedia,
              socials: {
                "twitter": MetadataViews.ExternalURL("https://twitter.com/ethos_io")
              }
            )
      }
      return nil 
    }

  }
  ```



### Suggested Contract 

1. The edition should only return the edition which the NFT belongs. 
2. The HTTPFile (ie. the thumbnail and the collection displays images) should be constructed with concat
3. The IPFS hash should also be stored on chain if possible. 
4. External URL in MetadataViews means the project website instead of the link to the image. 

```cadence
  pub enum Edition: UInt8 {
    pub case Frame
    pub case Painting
  }
``` 

```cadence
// Resource that represents the a Chapter2Bikes NFT
  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    pub let id: UInt64

    pub let edition: Chapter2Bikes.Edition     // <- this should use the Edition declared

    pub var metadata: {String: String}

    init(_edition: Chapter2Bikes.Edition, _metadata: {String: String}) {
      self.id = Chapter2Bikes.totalSupply
      self.edition = _edition
      self.metadata = _metadata

      // Total Supply
      Chapter2Bikes.totalSupply = Chapter2Bikes.totalSupply + 1

      // Edition Supply
      if (_edition == Edition.Frame) {
        Chapter2Bikes.frameEditionSupply = Chapter2Bikes.frameEditionSupply + 1
      } else if (_edition == Painting) {
        Chapter2Bikes.paintingEditionSupply = Chapter2Bikes.paintingEditionSupply + 1
      } else {
        // Invalid Edition
        panic("Edition is invalid. Options: 0(Frame) or 1(Painting)")
      }

      // Emit Minted Event
      emit Minted(id: self.id)
    }

    pub fun getViews(): [Type] {
      return [
          Type<MetadataViews.Display>(),
          Type<MetadataViews.Editions>(),
          Type<MetadataViews.ExternalURL>(),
          Type<MetadataViews.NFTCollectionData>(),
          Type<MetadataViews.NFTCollectionDisplay>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
          case Type<MetadataViews.Display>():
            return MetadataViews.Display(
                name: self.metadata["name"]!,
                description: self.metadata["description"]!,
                thumbnail: MetadataViews.HTTPFile(url: self.metadata["external_url"]!)
            )
          case Type<MetadataViews.Editions>():
            // 50 Frame editions and 20 Painting editions

            // Edition here, should only return the edition that the NFT belongs
            if self.edition = Edition.Frame {
                let frameEditionInfo = MetadataViews.Edition(name: "Chapter2Bikes Frame Edition", number: self.id, max: 50)
                return MetadataViews.Editions(editionList)
            } else if self.edition = Edition.Painting {
                let paintingEditionInfo = MetadataViews.Edition(name: "Chapter2Bikes Painting Edition", number: self.id, max: 20)
                return MetadataViews.Editions(editionList)
            }
            return MetadataViews.Editions([])
            
          case Type<MetadataViews.ExternalURL>():
            return MetadataViews.ExternalURL("https://ethos.mypinata.cloud/ipfs/{ipfs hash}/{collection id}-50-00.png")
          case Type<MetadataViews.NFTCollectionData>():
            return MetadataViews.NFTCollectionData(
                storagePath: Chapter2Bikes.CollectionStoragePath,
                publicPath: Chapter2Bikes.CollectionPublicPath,
                providerPath: /private/Chapter2BikesCollection,
                publicCollection: Type<&Chapter2Bikes.Collection{Chapter2Bikes.CollectionPublic}>(),
                publicLinkedType: Type<&Chapter2Bikes.Collection{Chapter2Bikes.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                providerLinkedType: Type<&Chapter2Bikes.Collection{Chapter2Bikes.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                  return <- Chapter2Bikes.createEmptyCollection()
                })
            )
          case Type<MetadataViews.NFTCollectionDisplay>():
            let frameMedia = MetadataViews.Media(
              file: MetadataViews.HTTPFile(url: "https://ethos.mypinata.cloud/ipfs/{ipfs hash}/{collection id}-50-00.png"),
              mediaType: "video/mp4"
            )
            let paintingMedia = MetadataViews.Media(
              file: MetadataViews.HTTPFile(url: "https://ethos.mypinata.cloud/ipfs/{ipfs hash}/{collection id}-20-00.png"),
              mediaType: "image/png"
            )
            return MetadataViews.NFTCollectionDisplay(
              name: "Chapter2Bikes Collection",
              description: "Chapter2Bikes collection description",
              externalURL: MetadataViews.ExternalURL("https://ethos.mypinata.cloud/ipfs/{ipfs hash}/{collection id}-50-00.png"),
              frameImage: frameMedia,
              paintingImage: paintingMedia,
              socials: {
                "twitter": MetadataViews.ExternalURL("https://twitter.com/ethos_io")
              }
            )
      }
      return nil 
    }

  }
  ```
