import AdminContract from "../contracts/AdminContract.cdc" 

transaction() {
    prepare(account: AuthAccount) {
        if account.borrow<&AdminContract.AdminProxy>(from: AdminContract.adminProxyStoragePath) == nil {
            account.save<@AdminContract.AdminProxy>(<- AdminContract.createAdminProxy(), to: AdminContract.adminProxyStoragePath)
            account.link<&AdminContract.AdminProxy{AdminContract.AdminProxyPublic}>(AdminContract.adminProxyPublicPath, target: AdminContract.adminProxyStoragePath)
        }
    }
}