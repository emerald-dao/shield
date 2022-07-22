import AdminContract from "../contracts/AdminContract.cdc" 

transaction(address: Address) {
    prepare(account: AuthAccount) {

        let cap = account.getCapability<&AdminContract.Admin>(AdminContract.adminPrivatePath)
        let targetCap = getAccount(address).getCapability<&AdminContract.AdminProxy{AdminContract.AdminProxyPublic}>(AdminContract.adminProxyPublicPath)
        let targetRef = targetCap.borrow() ?? panic("Cannot get reference to admin proxy")

        targetRef.setupCap(cap)

    }
}