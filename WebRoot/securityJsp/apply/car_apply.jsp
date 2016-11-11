<%@page import="com.framework.util.ConfigUtil"%>
<%@page import="com.system.entity.maintain.SessionInfo"%>
<%@page import="com.framework.util.WebMsgUtil"%>
<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>

<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
SessionInfo s = (SessionInfo) session.getAttribute(ConfigUtil.getSessionInfoName());
%>

<!DOCTYPE html>
<html>
  <head>
    <base href="<%=basePath%>">
    
    <title>My JSP 'Info_report.jsp' starting page</title>
    
	<meta http-equiv="pragma" content="no-cache">
	<meta http-equiv="cache-control" content="no-cache">
	<meta http-equiv="expires" content="0">    
	<meta http-equiv="keywords" content="keyword1,keyword2,keyword3">
	<meta http-equiv="description" content="This is my page">
	<!--
	<link rel="stylesheet" type="text/css" href="styles.css">
	-->
	<jsp:include page="../../inc.jsp"></jsp:include>

  </head>
  
  <body class="easyui-layout" data-options="fit:true,border:false">
	<div id="tb" style="padding:5px 5px;">
	<form method="post" id="searchForm">
		单据编号：<input class="easyui-textbox" id="applyNo" name="QUERY_t#applyNo_S_LK" data-options="prompt:'在此输入完整或部分单据编号...'" style="width:200px"></input>
		车辆种类：<input id="dictIdCarType" name="QUERY_t#dictIdCarType_S_EQ">
		组织：<input id="orgId" name="QUERY_t#orgId_S_EQ" style="width:200px">
		<br>
		是否保密：<input id="dictIdIsSecret" name="QUERY_t#dictIdIsSecret_S_EQ" style="width:200px">
		用车区域：<input id="dictIdRegion" name="QUERY_t#dictIdRegion_S_EQ" style="width:200px">
		<a href="javascript:void(0)" class="easyui-linkbutton" data-options="plain:true,iconCls:'ext-icon-zoom'"
				onclick="doSearch()">查询</a>
		<a href="javascript:void(0)" class="easyui-linkbutton" data-options="plain:true,iconCls:'ext-icon-zoom_out'"
				onclick="doClear()">清空条件</a>
	</form>
		<a href="javascript:void(0)" class="easyui-linkbutton" data-options="plain:true,iconCls:'ext-icon-note_add'"
				onclick="newApply()" style="">公务用车申请</a><!-- plain:true,iconCls:'ext-icon-note_add' -->
	</div>
	<div data-options="region:'center',fit:true,border:false">
		<table id="dg" data-options="fit:true,border:false">
		</table>
	</div>
	</body>
	<script>
		var grid;
		function doSearch(){
			grid.datagrid('load', $.extend(sys.serializeObject($("#searchForm")),{
				'QUERY_t#applyType_S_EQ' : '<%=WebMsgUtil.CARSENDTYPE_YD %>',
				'QUERY_t#newApplyId_S_ISNULL' : null,
				'QUERY_t#orgId_S_EQ' : '<%=s.getOrganization().getOrgId()%>'
			}));
		}
		function doClear() {
			$("#searchForm").form('clear');
		}
		$(function(){
			// 车型
			$('#dictIdCarType').combobox({
				editable : false,
				width : '200px',
				valueField : 'dictId',
				textField : 'dictName',
				url : sys.contextPath + '/maintain/dictionaryManage!doNotNeedSecurity_findAll.cxl',
				queryParams : {
					'QUERY_t#dictFlag_S_EQ' : '<%=WebMsgUtil.YOUXIAO %>',
					'QUERY_t#dictClasId_S_EQ' : 'CarType'
				},
				panelHeight : 'auto',
	            panelMaxHeight: '350px'
			});
			// 组织
			$('#orgId').combotree({
				editable : false,
				panelWidth : 300,
				panelHeight:'auto',
	            panelMaxHeight: '350px',
				idField:'id',
				textField:'text',
				parentField:'pid',
				url : sys.contextPath + '/maintain/sysOrganization!doNotNeedSecurity_comboTree.cxl?id=',
				onBeforeLoad : function(row, param) {
					parent.$.messager.progress({
						text : '数据加载中....'
					});
					if (row) {
						$('#orgId').combotree('tree').tree('options').url = sys.contextPath
								+ '/maintain/sysOrganization!doNotNeedSecurity_comboTree.cxl?id='
								+ row.id;
					}
				},
				onLoadSuccess : function(row, data) {
					parent.$.messager.progress('close');
				}
			});
			// 是否保密
			$('#dictIdIsSecret').combobox({
				editable : false,
				valueField : 'dictId',
				textField : 'dictName',
				url : sys.contextPath + '/maintain/dictionaryManage!doNotNeedSecurity_findAll.cxl',
				queryParams : {
					'QUERY_t#dictFlag_S_EQ' : '<%=WebMsgUtil.YOUXIAO %>',
					'QUERY_t#dictClasId_S_EQ' : 'IsSecret'
				},
				panelHeight : 'auto',
	            panelMaxHeight: '350px'
			});
			// 区域
			$('#dictIdRegion').combobox({
				editable : false,
				valueField : 'dictId',
				textField : 'dictName',
				url : sys.contextPath + '/maintain/dictionaryManage!doNotNeedSecurity_findAll.cxl',
				queryParams : {
					'QUERY_t#dictFlag_S_EQ' : '<%=WebMsgUtil.YOUXIAO %>',
					'QUERY_t#dictClasId_S_EQ' : 'Region'
				},
				panelHeight : 'auto',
	            panelMaxHeight: '350px'
			});
			
			grid = $('#dg').datagrid(
					{
					url : sys.contextPath + '/car/apply!grid.cxl',
					queryParams : {
						'QUERY_t#applyType_S_EQ' : '<%=WebMsgUtil.CARSENDTYPE_YD %>',
						'QUERY_t#newApplyId_S_ISNULL' : null,
						'QUERY_t#orgId_S_EQ' : '<%=s.getOrganization().getOrgId()%>'
					},
					striped : true,
					rownumbers : true,
					pagination : true,
					singleSelect : true,
					idField : 'applyId',
					sortName : 'applyNo',
					sortOrder : 'desc',
					pageSize : 30,
					toolbar:'#tb',
					method:'get',
					pageList : [ 10, 20, 30, 40, 50 ],
					columns : [ [ {
								width : '100',
								title : '编号',
								field : 'applyNo',
								sortable : true
								},{
								width : '100',
								title : '车辆种类',
								field : 'carType',
								sortable : true
								},{
								width : '150',
								title : '组织',
								field : 'orgName',
								sortable : true
								},{
								width : '70',
								title : '警牌/民牌',
								field : 'carPoliceUsed',
								sortable : true
								},{
								width : '70',
								title : '乘车人数',
								field : 'applyUsedPeople',
								sortable : false
								},{
								width : '150',
								title : '预计用车时间',
								field : 'applyUsingTime',
								sortable : true
								},{
								width : '150',
								title : '预计还车时间',
								field : 'applyRemandTime',
								sortable : true
								},{
								width : '70',
								title : '用车区域',
								field : 'region',
								sortable : true
								},{
								width : '80',
								title : '是否保密',
								field : 'isSecret',
								sortable : true
								},{
								width : '150',
								title : '审批状态',
								field : 'checkStatus',
								sortable : true
								},{
								title : '操作',
								field : 'options',
								width : '350',
								formatter : function(value, row) {
									var str = sys.formatString('<a href="javascript:void(0)" class="btn1" onclick="details(\'{0}\')" data-options="plain:true">详情</a>', row.applyId);
									if (row.dictIdCheckStatus == '<%=WebMsgUtil.CHECK_STATUS_START%>') {
										str += sys.formatString('<a href="javascript:void(0)" class="btn2" onclick="edit(\'{0}\')" data-options="plain:true">编辑</a>', row.applyId);
										str += sys.formatString('<a href="javascript:void(0)" class="btn3" onclick="del(\'{0}\')" data-options="plain:true">删除</a>', row.applyId);
										str += sys.formatString('<a href="javascript:void(0)" class="btn4" onclick="reApply(\'{0}\')" data-options="plain:true,disabled:true">重新申请</a>', row.applyId);
										if (row.preApplyId != undefined && row.preApplyId != '') {
											str += sys.formatString('<a href="javascript:void(0)" class="btn5" onclick="details(\'{0}\')" data-options="plain:true">查看原始单据</a>', row.preApplyId);
										} else {
											str += sys.formatString('<a href="javascript:void(0)" class="btn5" onclick="details(\'{0}\')" data-options="plain:true,disabled:true">查看原始单据</a>', row.preApplyId);
										}
									} else {
										str += sys.formatString('<a href="javascript:void(0)" class="btn2" onclick="edit(\'{0}\')" data-options="plain:true,disabled:true">编辑</a>', row.applyId);
										if ((row.dictIdCheckStatus == '<%=WebMsgUtil.CHECK_STATUS_REFUSE1%>' 
												|| row.dictIdCheckStatus == '<%=WebMsgUtil.CHECK_STATUS_REFUSE2%>')
												&& (row.newApplyId == undefined || row.newApplyId == '')) {
											str += sys.formatString('<a href="javascript:void(0)" class="btn3" onclick="del(\'{0}\')" data-options="plain:true">删除</a>', row.applyId);
											str += sys.formatString('<a href="javascript:void(0)" class="btn4" onclick="reApply(\'{0}\')" data-options="plain:true">重新申请</a>', row.applyId);
										} else {
											str += sys.formatString('<a href="javascript:void(0)" class="btn3" onclick="del(\'{0}\')" data-options="plain:true,disabled:true">删除</a>', row.applyId);
											str += sys.formatString('<a href="javascript:void(0)" class="btn4" onclick="reApply(\'{0}\')" data-options="plain:true,disabled:true">重新申请</a>', row.applyId);
										}
										if (row.preApplyId != undefined && row.preApplyId != '') {
											str += sys.formatString('<a href="javascript:void(0)" class="btn5" onclick="details(\'{0}\')" data-options="plain:true">查看原始单据</a>', row.preApplyId);
										} else {
											str += sys.formatString('<a href="javascript:void(0)" class="btn5" onclick="details(\'{0}\')" data-options="plain:true,disabled:true">查看原始单据</a>', row.preApplyId);
										}
									}
									return str;
								}
								} ] ],
								onBeforeLoad : function(param) {
									/* parent.$.messager.progress({
										text : '数据加载中....'
									}); */
								},
								onLoadSuccess : function(data) {
									$('.btn1').linkbutton({text:'详情', plain:true, height:18, iconCls:'ext-icon-zoom'});
									$('.btn2').linkbutton({text:'编辑', plain:true, height:18, iconCls:'ext-icon-page_white_edit'});
									$('.btn3').linkbutton({text:'删除', plain:true, height:18, iconCls:'ext-icon-delete'}); 
									$('.btn4').linkbutton({text:'重新申请', plain:true, height:18, iconCls:'ext-icon-note_add'}); 
									$('.btn5').linkbutton({text:'查看原始单据', plain:true, height:18, iconCls:'ext-icon-zoom'}); 
								}
					});
	});
	var details = function(id) {
		var dialog = parent.sys.modalDialog({
			title : '详情',
			url : sys.contextPath + '/securityJsp/apply/car_apply_approval_form.jsp?f=details&id=' + id,
			width: 750,
			height: 550,
			onClose:function(){dialog.dialog('destroy');},
			buttons : [ {
				text : '关闭',
				handler : function() {
					//dialog.find('iframe').get(0).contentWindow.submitForm(dialog, grid, parent.$);
					dialog.dialog('destroy');
				}
			} ]
		});
	};
	var edit = function(id) {
		var dialog = parent.sys.modalDialog({
			title : '编辑申请',
			url : sys.contextPath + '/securityJsp/apply/car_apply_detail.jsp?f=edit&id=' + id,
			width: 750,
			height: 500,
			onClose:function(){dialog.dialog('destroy');},
			buttons : [ {
				text : '保存',
				handler : function() {
					dialog.find('iframe').get(0).contentWindow.submitUpdate(dialog, grid, parent.$);
				}
			},{
				text : '关闭',
				handler : function() {
					//dialog.find('iframe').get(0).contentWindow.submitForm(dialog, grid, parent.$);
					dialog.dialog('destroy');
			} } ]
		});
	};
	var del = function(id) {
		parent.$.messager.confirm('确认', '是否要删除此单据?', function(r){
			if (r){
				var url = sys.contextPath + '/car/apply!delete.cxl';
				parent.$.messager.progress({
					text : '数据处理中....'
				});
				$.post(url, {"id":id}, function(result) {
					parent.$.messager.progress('close');
					var flag = '';
					if (result.success) {
						grid.datagrid('load');
						flag = 'info';
					} else {
						flag = 'error';
					}
					parent.$.messager.alert('提示', result.msg, flag);
				}, 'json');
			}
		});
	};
	//添加
	var newApply = function() {
		var dialog = parent.sys.modalDialog({
			title : '用车申请',
			url : sys.contextPath + '/securityJsp/apply/car_apply_detail.jsp',
			width: 750,
			height: 500,
			onClose:function(){dialog.dialog('destroy');},
			buttons : [ {
				text : '保存',
				handler : function() {
					/* if(typeof JSON == 'undefined'){
						$('head').append($("<script type='text/javascript' src='../../public/jslib/json2.js'>"));
					} */
					dialog.find('iframe').get(0).contentWindow.submitSave(dialog, grid, parent.$);
				}
			},{
				text : '关闭',
				handler : function() {
					//dialog.find('iframe').get(0).contentWindow.submitForm(dialog, grid, parent.$);
					dialog.dialog('destroy');
			} } ]
		});
	};
	//重新申请
	var reApply = function(id) {
		var dialog = parent.sys.modalDialog({
			title : '重新申请',
			url : sys.contextPath + '/securityJsp/apply/car_apply_detail.jsp?f=re&id=' + id,
			width: 750,
			height: 500,
			onClose:function(){dialog.dialog('destroy');},
			buttons : [ {
				text : '保存',
				handler : function() {
					/* if(typeof JSON == 'undefined'){
						$('head').append($("<script type='text/javascript' src='../../public/jslib/json2.js'>"));
					} */
					dialog.find('iframe').get(0).contentWindow.submitReApply(dialog, grid, parent.$);
				}
			},{
				text : '关闭',
				handler : function() {
					//dialog.find('iframe').get(0).contentWindow.submitForm(dialog, grid, parent.$);
					dialog.dialog('destroy');
			} } ]
		});
	};
</script>
</html>