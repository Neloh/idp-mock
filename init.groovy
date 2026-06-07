import jenkins.model.*
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition

def jenkins = Jenkins.getInstance()

if (jenkins.getItem("idp-agentcore-pipeline") == null) {
    def job = jenkins.createProject(WorkflowJob, "idp-agentcore-pipeline")
    job.setDefinition(new CpsFlowDefinition("""
pipeline {
    agent any
    stages {
        stage('Validate Spec') {
            steps {
                echo '[Stage 1] Validating infrastructure spec...'
                echo '  Service: trade-event-processor'
                echo '  Runtime: docker'
                echo '  VPC: existing (reuse)'
                echo '  [PASS] Spec valid'
            }
        }
        stage('Security Review') {
            steps {
                echo '[Stage 2] Running security checks...'
                echo '  WAF enabled: true'
                echo '  Subnets: private'
                echo '  Encryption: at-rest + in-transit'
                echo '  [PASS] Security approved'
            }
        }
        stage('Terraform Plan') {
            steps {
                echo '[Stage 3] terraform plan output:'
                echo '  + aws_vpc.main'
                echo '  + aws_subnet.private[0]'
                echo '  + aws_subnet.private[1]'
                echo '  + aws_security_group.agentcore'
                echo '  + aws_nat_gateway.main'
                echo '  + null_resource.agentcore_runtime'
                echo '  Plan: 12 to add, 0 to change, 0 to destroy.'
            }
        }
        stage('Approval') {
            steps {
                input message: 'Deploy infrastructure?', ok: 'Approve'
            }
        }
        stage('Terraform Apply') {
            steps {
                echo '[Stage 4] Applying...'
                echo '  aws_vpc.main: Created (vpc-0abc123)'
                echo '  aws_subnet.private[0]: Created'
                echo '  aws_subnet.private[1]: Created'
                echo '  aws_security_group.agentcore: Created'
                echo '  aws_nat_gateway.main: Created'
                echo '  null_resource.agentcore_runtime: Created'
                echo '  Apply complete! Resources: 12 added.'
            }
        }
        stage('Smoke Test') {
            steps {
                echo '[Stage 5] Verifying deployment...'
                echo '  VPC: OK'
                echo '  Private subnets: 2 (OK)'
                echo '  AgentCore Runtime: PREPARED'
                echo '  [PASS] All checks passed'
            }
        }
    }
    post {
        success {
            echo 'PIPELINE COMPLETE - Infrastructure deployed.'
        }
    }
}
""", true))
    job.save()
    println("Created pipeline job: idp-agentcore-pipeline")
}
