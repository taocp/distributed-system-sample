#include <signal.h>
#include <unistd.h>

#include <functional>
#include <iostream>
#include <vector>

#include <gflags/gflags.h>
#include <glog/logging.h>
#include <sofa/pbrpc/pbrpc.h>

#include "common/thread_pool.h"

#include "master.pb.h"

DECLARE_string(log_dir);

DECLARE_int32(taocipian_master_task_pool_thread_num);
DECLARE_string(taocipian_master_hostname);
DECLARE_string(taocipian_master_port);

namespace taocipian {
namespace master {

class MasterImpl : public taocipian::master::MasterServer
{
public:
    MasterImpl():
        task_pool_(new ::common::ThreadPool(FLAGS_taocipian_master_task_pool_thread_num)) {
            LOG(INFO) << "init master";
        }
    ~MasterImpl() {}

private:
    void DoEcho(const taocipian::master::EchoRequest* request,
                taocipian::master::EchoResponse* response,
                google::protobuf::Closure* done);
    void Echo(google::protobuf::RpcController* controller,
              const taocipian::master::EchoRequest* request,
              taocipian::master::EchoResponse* response,
              google::protobuf::Closure* done) {
        sofa::pbrpc::RpcController* cntl = static_cast<sofa::pbrpc::RpcController*>(controller);
        LOG(INFO) << "Echo for " << cntl->RemoteAddress() << std::endl;
        auto task = std::bind(&MasterImpl::DoEcho, this, request, response, done);
        task_pool_->AddTask(task);
    }

    ::common::ThreadPool* task_pool_;
};

void MasterImpl::DoEcho(const taocipian::master::EchoRequest* request,
                        taocipian::master::EchoResponse* response,
                        google::protobuf::Closure* done) {
    response->set_message("echo message: " + request->message());
    done->Run();
}

} // namespace master
} // namespace taocipian


void DoEcho(const taocipian::master::EchoRequest* request,
                taocipian::master::EchoResponse* response,
                google::protobuf::Closure* done);

bool ThreadInitFunc()
{
    return true;
}

void ThreadDestFunc()
{
}

int main(int argc, char* argv[])
{
    ::google::ParseCommandLineFlags(&argc, &argv, true);
    ::google::InitGoogleLogging(argv[0]);

    // Define an rpc server.
    sofa::pbrpc::RpcServerOptions options;
    options.work_thread_init_func = sofa::pbrpc::NewPermanentExtClosure(&ThreadInitFunc);
    options.work_thread_dest_func = sofa::pbrpc::NewPermanentExtClosure(&ThreadDestFunc);
    sofa::pbrpc::RpcServer rpc_server(options);

    // Start rpc server.
    if (!rpc_server.Start("0.0.0.0:" + FLAGS_taocipian_master_port)) {
        std::cerr << "start server failed" << std::endl;
        return 1;
    }

    // Register service.
    taocipian::master::MasterServer* master_service = new taocipian::master::MasterImpl();
    if (!rpc_server.RegisterService(master_service)) {
        std::cerr << "export service failed" << std::endl;
        return 2;
    }

    // Wait signal.
    rpc_server.Run();

    // Stop rpc server.
    rpc_server.Stop();

    // Delete closures.
    // Attention: should delete the closures after server stopped, or may be crash.
    delete options.work_thread_init_func;
    delete options.work_thread_dest_func;

    return 0;
}
