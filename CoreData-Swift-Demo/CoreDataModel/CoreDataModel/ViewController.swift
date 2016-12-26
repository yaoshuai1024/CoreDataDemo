//
//  ViewController.swift
//  CoreDataModel
//
//  Created by yaoshuai on 2016/12/26.
//  Copyright © 2016年 ys. All rights reserved.
//

import UIKit
import CoreData

private let cellID = "cellID"

class ViewController: UITableViewController,NSFetchedResultsControllerDelegate {
    
    private lazy var fetchedResultsController:NSFetchedResultsController<User> = {
        
        // 查询请求，必须要指定排序字段
        let fetchRequest:NSFetchRequest = User.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "username", ascending: true)]
        
        // 谓词，即查询条件
        fetchRequest.predicate = NSPredicate(format: "username contains '1'")
        
        // 查询结果控制器
        // sectionNameKeyPath：分组查询字段名
        let resultsVC = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.sharedManager.moc, sectionNameKeyPath: "city.cityname", cacheName: nil)
        resultsVC.delegate = self
        
        // 执行查询
        try? resultsVC.performFetch()
        
        return resultsVC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(NSHomeDirectory())
    }
    
    // MARK: - 添加数据
    @IBAction func newData(_ sender: Any) {
        let citynames = ["北京","上海","广州"]
        for cityname in citynames{
            let cityModel:City = NSEntityDescription.insertNewObject(forEntityName: "City", into: CoreDataManager.sharedManager.moc) as! City
            cityModel.cityname = cityname
            
            let count = arc4random_uniform(10) + 5;
            for i in 0..<count{
                let userModel:User = NSEntityDescription.insertNewObject(forEntityName: "User", into: CoreDataManager.sharedManager.moc) as! User
                userModel.username = "\(cityname)用户-\(i)"
                userModel.city = cityModel
            }
        }
        CoreDataManager.sharedManager.saveContext()
    }
    
    // MARK: - tableView数据源
    override func numberOfSections(in tableView: UITableView) -> Int {
        // 分组数量
        return fetchedResultsController.sections?.count ?? 0
        
        // 这个是所有数据
        // fetchedResultsController.fetchedObjects
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // 分组标题
        return fetchedResultsController.sections?[section].name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 分组里面的元素数量
        return fetchedResultsController.sections![section].objects?.count ?? 0
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        
        // 对应分组及对应分组里面的元素
        let userModel:User = fetchedResultsController.sections?[indexPath.section].objects?[indexPath.row] as! User
        
        cell.textLabel?.text = "\(userModel.username!)"
        
        return cell
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    // 查询结果控制器的数据一旦发生变化，就会被这个方法监听到
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

