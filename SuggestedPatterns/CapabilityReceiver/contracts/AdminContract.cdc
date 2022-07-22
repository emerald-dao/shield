// This contract is to demonstrate the use of Capability gated admin resource.

pub contract AdminContract {

    pub let adminStoragePath: StoragePath 
    pub let adminPrivatePath: PrivatePath 

    pub let adminProxyStoragePath: StoragePath 
    pub let adminProxyPublicPath: PublicPath 

    pub resource Admin {
        // admin functions here
    }

    pub resource interface AdminProxyPublic {
        pub fun setupCap(_ cap: Capability<&Admin>) 

    }

    pub resource AdminProxy : AdminProxyPublic {

        access(self) var cap: Capability<&Admin>?

        pub fun setupCap(_ cap: Capability<&Admin>) {
            pre{
                self.cap == nil : "Capability is already set" 
                cap.check() : "Capability is not valid"
            }
            self.cap=cap
        }

        pub fun borrow() : &Admin {
            return self.cap!.borrow()!
        }

        init(){
            self.cap=nil
        }
    }

    pub fun createAdminProxy() : @AdminProxy {
        return <- create AdminProxy()
    }

    init(){
        self.adminStoragePath= /storage/admin
        self.adminPrivatePath= /private/admin

        self.adminProxyStoragePath= /storage/adminProxy
        self.adminProxyPublicPath= /public/adminProxy

        self.account.save<@Admin>(<- create Admin() , to: self.adminStoragePath)
        self.account.link<&Admin>(self.adminPrivatePath, target: self.adminStoragePath)
    }

}