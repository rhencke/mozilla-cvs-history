/* -*- Mode: C -*- */
/*======================================================================
 FILE: icalvalue_cxx.cpp
 CREATOR: fnguyen 12/21/01
 (C) COPYRIGHT 2001, Critical Path
======================================================================*/

#ifndef ICALVALUE_CXX_H
#include "icalvalue_cxx.h"
#endif

typedef	char* string; // Will use the string library from STL

ICalValue::ICalValue() throw(icalerrorenum) : imp(icalvalue_new(ICAL_ANY_VALUE)){}

ICalValue::ICalValue(const ICalValue& v) throw (icalerrorenum) {
	imp = icalvalue_new_clone(v.imp);
	if (!imp) throw icalerrno;
}
ICalValue& ICalValue::operator=(const ICalValue& v) throw(icalerrorenum) {
	if (this == &v) return *this;

	if (imp != NULL)
	{
		icalvalue_free(imp);
		imp = icalvalue_new_clone(v.imp);
		if (!imp) throw icalerrno;
	}

	return *this;
}

ICalValue::~ICalValue(){
	if (imp != NULL) icalvalue_free(imp);
}

ICalValue::ICalValue(icalvalue* v) throw(icalerrorenum) : imp(v){
}

ICalValue::ICalValue(icalvalue_kind kind) throw(icalerrorenum) {
	imp = icalvalue_new(kind);
	if (!imp) throw icalerrno;
}

ICalValue::ICalValue(icalvalue_kind kind, string  str) throw(icalerrorenum) {
	imp = icalvalue_new_from_string(kind, str);
	if (!imp) throw icalerrno;
}

string ICalValue::as_ical_string(){
	return (string)icalvalue_as_ical_string(imp);
}
bool ICalValue::is_valid(){
	if (imp == NULL) return false;
	return (icalvalue_is_valid(imp) ? true : false);
}
icalvalue_kind ICalValue::isa(){
	return icalvalue_isa(imp);
}
int ICalValue::isa_value(void* value){
	return icalvalue_isa_value(value);
}

/* Special, non autogenerated value accessors */
void ICalValue::set_recur(struct icalrecurrencetype v){
	icalvalue_set_recur(imp, v);
}
struct icalrecurrencetype ICalValue::get_recur(){
	return icalvalue_get_recur(imp);
}

void ICalValue::set_trigger(struct icaltriggertype v){}
struct icaltriggertype ICalValue::get_trigger(){
	return icalvalue_get_trigger(imp);
}

void ICalValue::set_datetimeperiod(struct icaldatetimeperiodtype v){
	icalvalue_set_datetimeperiod(imp, v);
}
struct icaldatetimeperiodtype ICalValue::get_datetimeperiod(){
	return icalvalue_get_datetimeperiod(imp);
}

icalparameter_xliccomparetype ICalValue::compare(ICalValue& a, ICalValue& b){
	return icalvalue_compare(a, b);
}

/* Convert enumerations */
icalvalue_kind ICalValue::string_to_kind(string  str){
	return icalvalue_string_to_kind(str);
}
string ICalValue::kind_to_string(icalvalue_kind kind){
	return (string)icalvalue_kind_to_string(kind);
}

/* BOOLEAN */ 
int ICalValue::get_boolean(){
	return icalvalue_get_boolean(imp);
} 
void ICalValue::set_boolean(int v){
	icalvalue_set_boolean(imp, v);
}

/* UTC-OFFSET */ 
int ICalValue::get_utcoffset(){
	return icalvalue_get_utcoffset(imp);
} 
void ICalValue::set_utcoffset(int v){
	icalvalue_set_utcoffset(imp, v);
}

/* METHOD */ 
enum icalproperty_method ICalValue::get_method(){
	return icalvalue_get_method(imp);
} 
void ICalValue::set_method(enum icalproperty_method v){
	icalvalue_set_method(imp, v);
}

/* CAL-ADDRESS */ 
string ICalValue::get_caladdress(){
	return (string)icalvalue_get_caladdress(imp);
} 
void ICalValue::set_caladdress(string  v){
	icalvalue_set_caladdress(imp, v);
}

/* PERIOD */ 
struct icalperiodtype ICalValue::get_period(){
	return icalvalue_get_period(imp);
} 
void ICalValue::set_period(struct icalperiodtype v){
	icalvalue_set_period(imp, v);
}

/* STATUS */ 
enum icalproperty_status ICalValue::get_status(){
	return icalvalue_get_status(imp);
} 
void ICalValue::set_status(enum icalproperty_status v){
	icalvalue_set_status(imp, v);
}

/* BINARY */ 
string ICalValue::get_binary(){
	return (string)icalvalue_get_binary(imp);
} 
void ICalValue::set_binary(string  v){
	icalvalue_set_binary(imp, v);
}

/* TEXT */ 
string ICalValue::get_text(){
	return (string)icalvalue_get_text(imp);
} 
void ICalValue::set_text(string  v){
	icalvalue_set_text(imp, v);
}

/* DURATION */ 
struct icaldurationtype ICalValue::get_duration(){
	return icalvalue_get_duration(imp);
} 
void ICalValue::set_duration(struct icaldurationtype v){
	icalvalue_set_duration(imp, v);
}

/* INTEGER */ 
int ICalValue::get_integer(){
	return icalvalue_get_integer(imp);
} 
void ICalValue::set_integer(int v){
	icalvalue_set_integer(imp, v);
}

/* URI */ 
string ICalValue::get_uri(){
	return (string)icalvalue_get_uri(imp);
} 
void ICalValue::set_uri(string  v){
	icalvalue_set_uri(imp, v);
}

/* ATTACH */ 
icalattach *ICalValue::get_attach(){
	return icalvalue_get_attach(imp);
} 
void ICalValue::set_attach(icalattach *v){
	icalvalue_set_attach(imp, v);
}

/* CLASS */ 
enum icalproperty_class ICalValue::get_class(){
	return icalvalue_get_class(imp);
} 
void ICalValue::set_class(enum icalproperty_class v){
	icalvalue_set_class(imp, v);
}

/* FLOAT */ 
float ICalValue::get_float(){
	return icalvalue_get_float(imp);
} 
void ICalValue::set_float(float v){
	icalvalue_set_float(imp, v);
}

/* QUERY */ 
string ICalValue::get_query(){
	return (string)icalvalue_get_query(imp);
} 
void ICalValue::set_query(string  v){
	icalvalue_set_query(imp, v);
}

/* STRING */ 
string ICalValue::get_string(){
	return (string)icalvalue_get_string(imp);
} 
void ICalValue::set_string(string v){
	icalvalue_set_string(imp, v);
}

/* TRANSP */ 
enum icalproperty_transp ICalValue::get_transp(){
	return icalvalue_get_transp(imp);
} 
void ICalValue::set_transp(enum icalproperty_transp v){
	icalvalue_set_transp(imp, v);
}

/* DATE-TIME */ 
struct icaltimetype ICalValue::get_datetime(){
	return icalvalue_get_datetime(imp);
} 
void ICalValue::set_datetime(struct icaltimetype v){
	icalvalue_set_datetime(imp, v);
}

/* GEO */ 
struct icalgeotype ICalValue::get_geo(){
	return icalvalue_get_geo(imp);
} 
void ICalValue::set_geo(struct icalgeotype v){
	icalvalue_set_geo(imp, v);
}

/* DATE */ 
struct icaltimetype ICalValue::get_date(){
	return icalvalue_get_date(imp);
} 
void ICalValue::set_date(struct icaltimetype v){
	icalvalue_set_date(imp, v);
}

/* ACTION */ 
enum icalproperty_action ICalValue::get_action(){
	return icalvalue_get_action(imp);
} 
void ICalValue::set_action(enum icalproperty_action v){
	icalvalue_set_action(imp, v);
}
