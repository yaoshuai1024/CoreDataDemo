import UIKit
import CoreData

// coredata管理器
class CoreDataManager: NSObject {
    
    // 单例
    static let sharedManager:CoreDataManager = CoreDataManager()
    
    // 私有化构造函数
    override private init(){
        super.init()
    }
    
    // 持久化容器，可以提供管理上下文
    // iOS10推出，为了兼容低版本，我们这里设置private，不再使用，手动方式实现管理对象上下文，见下一个属性
    // 包含了CoreDataStack中的所有核心对象,下面是很重要的三个对象
    // viewContext: NSManagedObjectContext - 管理上下文，主要负责数据操作
    // managedObjectModel: NSManagedObjectModel - 管理对象模型
    // persistentStoreCoordinator: NSPersistentStoreCoordinator
    private lazy var persistentContainer: NSPersistentContainer? = {
        
        // CoreData的核心对象都不是线程安全的
        // 使用同步锁/互斥锁，保证线程安全
        objc_sync_enter(self)
        // 实例化对象，需要指定数据模型
        // 指定的名称 == 数据模型的名称 == 沙盒中数据库的名称
        // let container = NSPersistentContainer(name: "demo_db")
        
        // 管理对象模型，参数传入nil，自动将mainBundle中所有的数据模型合并
        let model = NSManagedObjectModel.mergedModel(from: nil)!
        
        // 实例化持久化容器
        // 参数一：数据库名字
        // 参数二：合并后的模型
        var container:NSPersistentContainer? = NSPersistentContainer(name: "ys.db", managedObjectModel: model)
        
        
        // “同步方式” 加载 “持久化存储” -> 本质是 打开/新建/修改数据库(同步方式，保证线程安全)
        container?.loadPersistentStores(completionHandler: { (storeDescription, error) in
            // 判断创建数据库是否出现错误
            if let error = error as NSError? {
                /*
                 常见错误：
                 1、目录不存在，或者禁止写入，无法创建数据库文件
                 2、设备存储空间不足
                 3、由于权限或设备锁定时的数据保护，不能访问持久化存储
                 4、数据库不能被迁移到当前模型版本
                 */
                print("打开/新建/修改数据库出现错误：\(error)")
                container = nil
            }
        })
        
        objc_sync_exit(self)
        
        return container
    }()
    
    // 管理对象上下文
    lazy var moc:NSManagedObjectContext = {
        // 同步锁/互斥锁保护
        objc_sync_exit(self)
        
        // 实例化管理上下文
        var mocObj:NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        // 实例化对象模型
        let momObj = NSManagedObjectModel.mergedModel(from: nil)!
        
        // 持久化存储调度器
        let psc = NSPersistentStoreCoordinator(managedObjectModel: momObj)
        
        // 添加数据库
        // 参数1：数据存储类型
        // 参数3：保存SqLite数据库文件的URL
        // 参数4：设置数据库选项
        let cacheDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!
        let path = (cacheDir as NSString).appendingPathComponent("ys.db")
        let dict = [NSMigratePersistentStoresAutomaticallyOption:true,
                    NSInferMappingModelAutomaticallyOption:true]
        
        let persistentStore = try? psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: URL(fileURLWithPath: path), options: dict)
        
        if persistentStore != nil{
            // 给管理上下文指定存储调度器
            mocObj.persistentStoreCoordinator = psc
        }
        else{
            print("打开/新建/修改数据库出错")
            //            mocObj = nil
        }
        
        objc_sync_exit(self)
        
        return mocObj
    }()
    
    // 保存上下文
    func saveContext () {
        //        if let context = moc{
        // 事务：可以保存多个数据，不一定每次数据发生变化都需要保存，可以一次性保存
        if moc.hasChanges {
            do {
                try moc.save()
            } catch {
                let nserror = error as NSError
                print("保存数据出错：\(nserror)")
            }
        }
        //        }
    }
}
